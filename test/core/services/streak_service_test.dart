import 'package:aykitap/core/models/streak.dart';
import 'package:aykitap/core/navigation/root_navigator.dart';
import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/core/widgets/streak_goal_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StreakOverview _overview({required bool goalMet}) {
  final base = DateTime(2026, 1, 1);
  return StreakOverview(
    currentStreak: 1,
    bestStreak: 1,
    goalMinMinutes: 15,
    today: StreakDay(
        date: base, seconds: 0, minutes: 0, pages: 0, goalMet: goalMet),
    week: List.generate(
      7,
      (i) => StreakWeekDay(
        weekday: i + 1,
        date: base.add(Duration(days: i)),
        seconds: 0,
        minutes: 0,
        pages: 0,
        goalMet: false,
      ),
    ),
    thisMonth: const StreakMonthSummary(
        month: '2026-01', pages: 0, minutes: 0, daysMet: 0),
    lastMonth: const StreakMonthSummary(
        month: '2025-12', pages: 0, minutes: 0, daysMet: 0),
    rewardRules: const [],
  );
}

StreakReportResult _report({required int minutes, required int pages}) =>
    StreakReportResult(
      today: StreakDay(
        date: DateTime(2026, 1, 1),
        seconds: minutes * 60,
        minutes: minutes,
        pages: pages,
        goalMet: true,
      ),
      currentStreak: 2,
      bestStreak: 2,
      rewards: const [],
    );

// `rootNavigatorKey.currentState?.overlay?.context` (what
// `StreakGoalCelebration.show` is actually given) is the *Navigator's own*
// Overlay's context — `Overlay.of()` only searches ancestors, so without an
// extra outer Overlay above the whole app, that lookup never finds one, even
// though the pattern is unrelated to anything under test here.
Widget _appWithOuterOverlay() => Directionality(
      textDirection: TextDirection.ltr,
      child: Overlay(initialEntries: [
        OverlayEntry(
          builder: (_) => MaterialApp(
            navigatorKey: rootNavigatorKey,
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      ]),
    );

void main() {
  // StreakService is a process-lifetime singleton — every test needs a
  // clean slate, same reasoning as [StreakService.resetForTest]'s own doc
  // comment.
  setUp(() => StreakService.instance.resetForTest());
  tearDown(() => StreakService.instance.resetForTest());

  testWidgets(
      'a false-to-true goal report shows the celebration once, with the right minutes/pages',
      (tester) async {
    await tester.pumpWidget(_appWithOuterOverlay());

    final service = StreakService.instance;
    service.debugSeedOverviewForTesting(_overview(goalMet: false));
    service.debugApplyReportForTesting(_report(minutes: 20, pages: 10));
    await tester.pump();

    expect(find.byType(StreakGoalCelebration), findsOneWidget);
    final celebration = tester
        .widget<StreakGoalCelebration>(find.byType(StreakGoalCelebration));
    expect(celebration.minutes, 20);
    expect(celebration.pages, 10);
  });

  testWidgets(
      'a goal already met this session does not replay the celebration on a later report',
      (tester) async {
    await tester.pumpWidget(_appWithOuterOverlay());

    final service = StreakService.instance;
    // Simulates the goal having already been completed earlier this
    // session (e.g. a prior report, or a `refresh()` that picked up an
    // already-met day) — the guard is `today.goalMet` staying true, not a
    // persisted "already shown" flag.
    service.debugSeedOverviewForTesting(_overview(goalMet: true));
    service.debugApplyReportForTesting(_report(minutes: 30, pages: 15));
    await tester.pump();

    expect(find.byType(StreakGoalCelebration), findsNothing);
  });

  testWidgets(
      'a second report on the same already-completed day never re-fires',
      (tester) async {
    await tester.pumpWidget(_appWithOuterOverlay());

    final service = StreakService.instance;
    service.debugSeedOverviewForTesting(_overview(goalMet: false));

    service.debugApplyReportForTesting(_report(minutes: 20, pages: 10));
    await tester.pump();
    expect(find.byType(StreakGoalCelebration), findsOneWidget);

    // A later report the same day (more reading, same already-met goal)
    // must not show a second one — this is what stands in for "app went to
    // background and a fresh report landed after returning to foreground".
    service.debugApplyReportForTesting(_report(minutes: 45, pages: 20));
    await tester.pump();
    expect(find.byType(StreakGoalCelebration), findsOneWidget);
  });
}
