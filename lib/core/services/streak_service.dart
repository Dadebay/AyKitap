import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak.dart';
import '../navigation/root_navigator.dart';
import '../network/api_exception.dart';
import '../widgets/streak_goal_celebration.dart';
import '../widgets/streak_reward_dialog.dart';
import 'account_service.dart';
import 'analytics_service.dart';
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
  // A tick that fails to send stays here instead of being dropped, so the
  // next successful report carries the running total.
  //
  // Persisted (see [_savePending]): reading offline and then closing the app
  // used to lose everything buffered, which is exactly the case this is for
  // — someone reads on the bus with no signal, the app is swiped away, and
  // the reading never happened as far as the streak is concerned. Three ints
  // on disk, rewritten about once a minute while reading.
  int _pendingSeconds = 0;
  int _pendingPages = 0;
  int? _pendingBookId;

  static const _kPendingSeconds = 'streak_pending_seconds';
  static const _kPendingPages = 'streak_pending_pages';
  static const _kPendingBookId = 'streak_pending_book_id';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _pendingRestored = false;

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
    _pendingRestored = false;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Test-only seed for [_overview] — lets a test set up a baseline
  /// `today.goalMet` before exercising [debugApplyReportForTesting], with no
  /// network call. Never called from production code.
  @visibleForTesting
  void debugSeedOverviewForTesting(StreakOverview overview) {
    _overview = overview;
    _loaded = true;
  }

  /// Test-only hook into the same false → true detection [_report] runs
  /// after a real `POST /streaks/report` response — lets a widget test
  /// exercise the goal-completion celebration without a network call.
  /// Never called from production code.
  @visibleForTesting
  void debugApplyReportForTesting(StreakReportResult result) =>
      _applyReport(result);

  /// Fetches `GET /streaks/me` once; later calls no-op until [refresh] is
  /// called explicitly. Safe for every screen that needs streak data to
  /// call without worrying about duplicate requests.
  Future<void> load() async {
    // Before the fetch, and on every launch: whatever was buffered when the
    // app was last closed is reading the reader has already done.
    await _restorePending();
    _watchConnectivity();
    if (_loaded) return;
    await refresh();
    // Now that a token and a connection have both been proven to work, send
    // anything that was waiting. A zero-second report is the flush: [_report]
    // sends the accumulated total, not its argument.
    if (_pendingSeconds > 0) unawaited(_report(seconds: 0));
  }

  /// Reads the buffer left by a previous run. Once per process — a second
  /// call would add the same seconds again on top of whatever is already in
  /// memory.
  Future<void> _restorePending() async {
    if (_pendingRestored) return;
    _pendingRestored = true;
    final prefs = await SharedPreferences.getInstance();
    _pendingSeconds += prefs.getInt(_kPendingSeconds) ?? 0;
    _pendingPages += prefs.getInt(_kPendingPages) ?? 0;
    _pendingBookId ??= prefs.getInt(_kPendingBookId);
    if (_pendingSeconds > 0 && kDebugMode) {
      debugPrint('\x1B[32m\x1B[1m🔥 STREAK — restored \$_pendingSeconds s / '
          '\$_pendingPages page(s) buffered offline\x1B[0m');
    }
  }

  /// Sends the buffer the moment a connection comes back, instead of waiting
  /// for the reader to open a book again — someone who read offline and then
  /// put the phone down would otherwise not be credited until their next
  /// reading session, which may be the next day, after the streak has
  /// already broken.
  void _watchConnectivity() {
    if (_connectivitySub != null) return;
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((result) => result != ConnectivityResult.none);
      if (!online || _pendingSeconds <= 0) return;
      await _report(seconds: 0);
    });
  }

  /// Mirrors the buffer to disk after every change to it.
  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pendingSeconds <= 0 && _pendingPages <= 0) {
      await prefs.remove(_kPendingSeconds);
      await prefs.remove(_kPendingPages);
      await prefs.remove(_kPendingBookId);
      return;
    }
    await prefs.setInt(_kPendingSeconds, _pendingSeconds);
    await prefs.setInt(_kPendingPages, _pendingPages);
    final bookId = _pendingBookId;
    if (bookId != null) await prefs.setInt(_kPendingBookId, bookId);
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
      _logRewardRules();
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
    unawaited(_savePending());
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
  /// Prints the reward configuration the backend is actually running with.
  ///
  /// None of it is decided here: `goal_min_minutes`, every `reward_rules`
  /// entry, and whether a milestone was crossed all come from the server
  /// (see [StreakRewardRule] and `POST /streaks/report`'s `rewards[]`). So
  /// "is 30 days of 15 minutes really 10 TMT?" can only be answered by
  /// looking at what it sends — which is this line.
  void _logRewardRules() {
    if (!kDebugMode) return;
    final o = _overview;
    if (o == null) return;
    debugPrint('\x1B[32m\x1B[1m🔥 STREAK config — daily goal: '
        '${o.goalMinMinutes} min, ${o.rewardRules.length} reward rule(s), '
        'current streak: ${o.currentStreak}\x1B[0m');
    for (final r in o.rewardRules) {
      final prize = r.rewardType == StreakRewardType.balance
          ? '${r.amount} TMT to balance'
          : '${r.monthCount} month(s) of subscription';
      debugPrint('\x1B[32m\x1B[1m🔥   ${r.dayCount} days in a row → $prize'
          '${r.isRepeating ? " (repeats)" : " (once)"}\x1B[0m');
    }
  }

  void _notify() => notifyListeners();
}
