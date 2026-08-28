part of 'streak_service.dart';

/// [StreakService]'s history pagination + report/reward pipeline — split
/// out of streak_service.dart to keep that file under the 200-line limit.
/// Pure mechanical move: every expression here is unchanged from before the
/// split. `notifyListeners()` is `@protected` and can't be called directly
/// from an extension, so these use the `_notify()` wrapper added to the main
/// class instead. `_showRewards`'s `AccountService.instance.refresh()` was
/// left as `.instance` rather than `context.read<AccountService>()`: unlike
/// a widget/State, `StreakService` has no `BuildContext` of its own — the
/// `context` used here is a one-off, nullable value pulled from
/// `rootNavigatorKey` purely to show a dialog, and gating the refresh on
/// that being non-null would silently drop it whenever no dialog is
/// currently showable, which is a real behavior change, not a mechanical one.
extension _StreakServiceReporting on StreakService {
  Future<void> _loadHistoryPage() async {
    if (_historyLoading) return;
    _historyLoading = true;
    // `loadHistory()` is called straight from `StreakScreen.initState`, so
    // this first notify can land synchronously inside that widget's build
    // pass — before anything has yielded to the event loop — and trip
    // Provider's "setState() called during build" for any ancestor already
    // listening. Deferring to a microtask keeps the loading spinner but
    // pushes the notification past the current build.
    scheduleMicrotask(_notify);
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
      _notify();
    }
  }

  Future<void> _report({required int seconds, int? bookId}) async {
    if (seconds > 0) _pendingSeconds += seconds;
    if (bookId != null) _pendingBookId = bookId;
    if (_pendingSeconds <= 0) return;

    final sendSeconds = _pendingSeconds;
    final sendPages = _pendingPages;
    try {
      final result = await StreakApiService.report(
          seconds: sendSeconds,
          pages: sendPages > 0 ? sendPages : null,
          bookId: _pendingBookId);
      _pendingSeconds = 0;
      _pendingPages = 0;
      _applyReport(result);
      _notify();
      unawaited(HomeScreenWidgetService.syncStreak(
        streak: currentStreak,
        bestStreak: bestStreak,
        todayPages: todayPages,
        goalMinutes: goalMinMinutes,
        weekRead: weekRead,
      ));
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
    final completedNow = !current.today.goalMet && result.today.goalMet;
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
    if (completedNow) {
      unawaited(AnalyticsService.instance.logReadingGoalCompleted(
        pages: result.today.pages,
        minutes: result.today.minutes,
        streak: result.currentStreak,
      ));
      final context = rootNavigatorKey.currentState?.overlay?.context;
      if (context != null) {
        StreakGoalCelebration.show(
          context,
          minutes: result.today.minutes,
          pages: result.today.pages,
        );
      }
    }
  }

  List<StreakWeekDay> _mergeToday(List<StreakWeekDay> week, StreakDay today) {
    return week.map((d) {
      final sameDay = d.date.year == today.date.year &&
          d.date.month == today.date.month &&
          d.date.day == today.date.day;
      if (!sameDay) return d;
      return StreakWeekDay(
          weekday: d.weekday,
          date: d.date,
          seconds: today.seconds,
          minutes: today.minutes,
          pages: today.pages,
          goalMet: today.goalMet);
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
