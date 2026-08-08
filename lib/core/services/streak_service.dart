import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/streak.dart';
import '../navigation/root_navigator.dart';
import '../network/api_exception.dart';
import '../widgets/streak_reward_dialog.dart';
import 'account_service.dart';
import 'streak_api_service.dart';

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

  Future<void> _loadHistoryPage() async {
    if (_historyLoading) return;
    _historyLoading = true;
    // `loadHistory()` is called straight from `StreakScreen.initState`, so
    // this first notify can land synchronously inside that widget's build
    // pass — before anything has yielded to the event loop — and trip
    // Provider's "setState() called during build" for any ancestor already
    // listening. Deferring to a microtask keeps the loading spinner but
    // pushes the notification past the current build.
    scheduleMicrotask(notifyListeners);
    try {
      final result = await StreakApiService.getHistory(page: _historyPage + 1);
      _history.addAll(result.items);
      _historyPage = result.page;
      _historyHasMore = result.hasMore;
    } on ApiException {
      // Leave whatever's already loaded — "Daha fazla" just stays tappable
      // so the user can retry.
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  /// Active-reading ping — call every 60s while the reader is in the
  /// foreground with a book on screen (the contract's mandatory cadence).
  Future<void> recordActiveSeconds(int seconds, {int? bookId}) => _report(seconds: seconds, bookId: bookId);

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
  Future<void> flushResidual({int seconds = 0, int? bookId}) => _report(seconds: seconds, bookId: bookId);

  Future<void> _report({required int seconds, int? bookId}) async {
    if (seconds > 0) _pendingSeconds += seconds;
    if (bookId != null) _pendingBookId = bookId;
    if (_pendingSeconds <= 0) return;

    final sendSeconds = _pendingSeconds;
    final sendPages = _pendingPages;
    try {
      final result = await StreakApiService.report(seconds: sendSeconds, pages: sendPages > 0 ? sendPages : null, bookId: _pendingBookId);
      _pendingSeconds = 0;
      _pendingPages = 0;
      _applyReport(result);
      notifyListeners();
      if (result.rewards.isNotEmpty) unawaited(_showRewards(result.rewards));
    } on ApiException {
      // Offline or a server error: leave `_pendingSeconds`/`_pendingPages`
      // as they are — the next successful call sends the running total.
    }
  }

  /// Folds a report's response into [_overview] without a full `/streaks/me`
  /// refetch — swaps in the fresh `today`/streak counts and the matching
  /// day of `week`.
  void _applyReport(StreakReportResult result) {
    final current = _overview;
    if (current == null) return;
    _overview = StreakOverview(
      currentStreak: result.currentStreak,
      bestStreak: result.bestStreak,
      goalMinMinutes: current.goalMinMinutes,
      today: result.today,
      week: _mergeToday(current.week, result.today),
      thisMonth: current.thisMonth,
      lastMonth: current.lastMonth,
      rewardRules: current.rewardRules,
    );
  }

  List<StreakWeekDay> _mergeToday(List<StreakWeekDay> week, StreakDay today) {
    return week.map((d) {
      final sameDay = d.date.year == today.date.year && d.date.month == today.date.month && d.date.day == today.date.day;
      if (!sameDay) return d;
      return StreakWeekDay(weekday: d.weekday, date: d.date, seconds: today.seconds, minutes: today.minutes, pages: today.pages, goalMet: today.goalMet);
    }).toList();
  }

  Future<void> _showRewards(List<StreakReward> rewards) async {
    // A reward also bumps the server-side balance/subscription — pick that
    // up so it's already current by the time the dialog's CTA closes.
    unawaited(AccountService.instance.refresh());
    for (final reward in rewards) {
      final context = rootNavigatorKey.currentState?.overlay?.context;
      if (context == null) return;
      await StreakRewardDialog.show(context, reward);
    }
  }
}
