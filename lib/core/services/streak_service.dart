import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/streak.dart';
import '../navigation/root_navigator.dart';
import '../network/api_exception.dart';
import '../widgets/streak_reward_dialog.dart';
import 'account_service.dart';
import 'home_screen_widget_service.dart';
import 'streak_api_service.dart';

part 'streak_service_reporting.dart';

/// Server-backed reading streak (see the backend's `streak-apis.md`
/// contract — `POST /streaks/report`, `GET /streaks/me`, `GET
/// /streaks/history`). Used to be an entirely on-device mock tally before
/// this endpoint existed; [ReaderProvider]/[PdfReaderScreen]/
/// [CbzReaderScreen] report active-reading seconds + page deltas here,
/// [StreakScreen]/[ProfileScreen] read [overview] for everything the UI
/// shows.
class StreakService extends ChangeNotifier {
  StreakService._();
  static final instance = StreakService._();

  StreakOverview? _overview;
  bool _loading = false;
  String? _error;
  bool _loaded = false;

  StreakOverview? get overview => _overview;
  bool get isLoading => _loading;
  String? get error => _error;

  int get currentStreak => _overview?.currentStreak ?? 0;
  int get bestStreak => _overview?.bestStreak ?? 0;
  int get goalMinMinutes => _overview?.goalMinMinutes ?? 15;
  int get todayPages => _overview?.today.pages ?? 0;
  StreakDay? get today => _overview?.today;
  StreakMonthSummary? get thisMonth => _overview?.thisMonth;
  StreakMonthSummary? get lastMonth => _overview?.lastMonth;
  List<StreakRewardRule> get rewardRules => _overview?.rewardRules ?? const [];

  /// Mon..Sun, true where that day's goal was met — [StreakWeekRow]'s input
  /// shape, unchanged by the move to a server-backed streak.
  List<bool> get weekRead {
    final week = _overview?.week;
    if (week == null || week.length != 7) return List.filled(7, false);
    return week.map((d) => d.goalMet).toList();
  }

  // ── Reading history (GET /streaks/history) ──────────────────────────────
  final List<StreakDay> _history = [];
  int _historyPage = 0;
  bool _historyHasMore = true;
  bool _historyLoading = false;

  List<StreakDay> get history => List.unmodifiable(_history);
  bool get historyHasMore => _historyHasMore;
  bool get historyLoading => _historyLoading;

  // ── Offline buffering ────────────────────────────────────────────────
  // Session-only by design: a tick that fails to send stays here instead of
  // being dropped, so the *next* tick's body carries the running total and
  // nothing reported while offline is lost as long as the app stays open.
  // Not persisted to disk — an app kill while offline does lose whatever's
  // buffered at that point.
  int _pendingSeconds = 0;
  int _pendingPages = 0;
  int? _pendingBookId;

  /// Clears every field back to a fresh instance's defaults. This is the
  /// app's process-lifetime singleton, so tests that exercise it (directly or
  /// via [ReaderProvider]) need a way to undo that state between cases —
  /// there is no other way to get a clean [StreakService] in a test process.
  @visibleForTesting
  void resetForTest() {
    _overview = null;
    _loading = false;
    _error = null;
    _loaded = false;
    _history.clear();
    _historyPage = 0;
    _historyHasMore = true;
    _historyLoading = false;
    _pendingSeconds = 0;
    _pendingPages = 0;
    _pendingBookId = null;
  }

  /// Fetches `GET /streaks/me` once; later calls no-op until [refresh] is
  /// called explicitly. Safe for every screen that needs streak data to
  /// call without worrying about duplicate requests.
  Future<void> load() async {
    if (_loaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    // No `notifyListeners()` here, before the `await` below — `load()` is
    // called straight from several screens' `initState`, and notifying
    // synchronously at that point (before any widget has actually yielded
    // back to the event loop) trips Provider's "setState() called during
    // build" — a widget elsewhere in the same build pass can already be
    // listening to this service. `isLoading` isn't rendered anywhere, so
    // there's nothing lost by only notifying once this actually resolves.
    _loading = true;
    _error = null;
    try {
      _overview = await StreakApiService.getMe();
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
      unawaited(HomeScreenWidgetService.syncStreak(
        streak: currentStreak,
        bestStreak: bestStreak,
        todayPages: todayPages,
        goalMinutes: goalMinMinutes,
        weekRead: weekRead,
      ));
    }
  }

  /// Resets to page 1 — call when the Streak screen (re)opens.
  Future<void> loadHistory() async {
    _history.clear();
    _historyPage = 0;
    _historyHasMore = true;
    await _loadHistoryPage();
  }

  /// The "Daha fazla" button's action — appends the next page.
  Future<void> loadMoreHistory() async {
    if (!_historyHasMore || _historyLoading) return;
    await _loadHistoryPage();
  }

  /// Active-reading ping — call every 60s while the reader is in the
  /// foreground with a book on screen (the contract's mandatory cadence).
  Future<void> recordActiveSeconds(int seconds, {int? bookId}) =>
      _report(seconds: seconds, bookId: bookId);

  /// A page turned. Bundled into whichever report ([recordActiveSeconds]'s
  /// next tick, or [flushResidual]) goes out next rather than its own
  /// network call — the backend takes `pages` as part of the same `seconds`
  /// report, not a separate endpoint.
  void recordPageRead({int count = 1}) {
    if (count <= 0) return;
    _pendingPages += count;
  }

  /// Call once on pause/background/close with whatever active-reading
  /// seconds have elapsed since the last periodic tick (0 if none) — sends
  /// them immediately with any buffered pages instead of waiting for the
  /// next 60s mark, so a short reading burst still counts.
  Future<void> flushResidual({int seconds = 0, int? bookId}) =>
      _report(seconds: seconds, bookId: bookId);

  // notifyListeners() is @protected — the history/report methods in
  // streak_service_reporting.dart live in an extension, not a subclass, so
  // they call this thin wrapper instead of notifyListeners directly.
  void _notify() => notifyListeners();
}
