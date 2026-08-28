import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:aykitap/core/theme/app_motion.dart';
import 'package:aykitap/core/widgets/streak_week_row.dart';
import 'package:aykitap/modules/home/widgets/stagger_fade_in.dart';
import 'package:aykitap/modules/payment/widgets/subscription_success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The particle color [StreakWeekRow] draws during a day's celebration —
/// matched against decoration color rather than a dedicated widget type,
/// since the particles are plain [Container]s.
bool _isParticle(Widget widget) =>
    widget is Container &&
    widget.decoration is BoxDecoration &&
    (widget.decoration! as BoxDecoration).color == const Color(0xFFFFB34D);

Widget _app(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('Home stagger becomes immediate when reduced motion is enabled',
      (tester) async {
    await tester.pumpWidget(_app(
      const StaggerFadeIn(index: 4, child: Text('Shelf')),
      reduceMotion: true,
    ));

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(StaggerFadeIn),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
    expect(find.text('Shelf'), findsOneWidget);
  });

  testWidgets('existing streak days do not celebrate again on mount',
      (tester) async {
    await tester.pumpWidget(_app(
      const StreakWeekRow(
          weekRead: [true, true, false, false, false, false, false]),
    ));

    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('🔥'), findsNWidgets(2));
  });

  testWidgets('a newly completed streak day runs one finite celebration',
      (tester) async {
    var week = List<bool>.filled(7, false);
    late StateSetter update;
    await tester.pumpWidget(_app(
      StatefulBuilder(builder: (context, setState) {
        update = setState;
        return StreakWeekRow(weekRead: week);
      }),
    ));

    update(() => week = [true, ...week.skip(1)]);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.text('🔥'), findsOneWidget);
  });

  testWidgets(
      'subscription success shows the unlocked state with reduce motion',
      (tester) async {
    await tester.pumpWidget(_app(
      const SubscriptionSuccessDialog(planLabel: 'Monthly'),
      reduceMotion: true,
    ));
    await tester.pump();

    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    expect(find.textContaining('Monthly'), findsOneWidget);
  });

  testWidgets('subscription success stays the purchase headline by default',
      (tester) async {
    await tester.pumpWidget(_app(
      const SubscriptionSuccessDialog(planLabel: 'Monthly'),
      reduceMotion: true,
    ));
    await tester.pump();

    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsOneWidget);
    expect(find.text(PaymentStrings.subscriptionRestoredTitle), findsNothing);
  });

  testWidgets(
      'restored purchases show the restored headline, not the purchase one',
      (tester) async {
    await tester.pumpWidget(_app(
      const SubscriptionSuccessDialog(planLabel: 'Monthly', restored: true),
      reduceMotion: true,
    ));
    await tester.pump();

    expect(find.text(PaymentStrings.subscriptionRestoredTitle), findsOneWidget);
    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsNothing);
  });

  group('StaggerFadeIn', () {
    double translateY(WidgetTester tester) => tester
        .widget<Transform>(find.descendant(
            of: find.byType(StaggerFadeIn), matching: find.byType(Transform)))
        .transform
        .getTranslation()
        .y;

    testWidgets('starts 10px below its resting position and settles to it',
        (tester) async {
      await tester.pumpWidget(_app(
        const StaggerFadeIn(index: 0, child: SizedBox(key: Key('child'))),
      ));

      // One frame in — index 0's zero delay has fired, but the 280ms
      // entrance itself hasn't had time to advance yet. An explicit
      // (rather than bare) duration forces the pending zero-delay Timer to
      // actually run before this frame draws.
      await tester.pump(const Duration(milliseconds: 1));
      expect(translateY(tester), closeTo(10, 0.5));

      await tester
          .pump(AppMotion.sectionEntrance + const Duration(milliseconds: 50));
      expect(translateY(tester), closeTo(0, 0.01));
    });

    testWidgets('keeps its post-entrance state alive in a lazy list',
        (tester) async {
      // AutomaticKeepAliveClientMixin is what stops a scroll far enough to
      // leave a SliverList's cache extent from disposing and later
      // replaying this section's entrance — verified here at the
      // `wantKeepAlive` contract level rather than scrolling a real list.
      final key = GlobalKey<State<StaggerFadeIn>>();
      await tester.pumpWidget(_app(
        StaggerFadeIn(key: key, index: 0, child: const SizedBox()),
      ));
      await tester.pumpAndSettle();

      final state = key.currentState!;
      // ignore: invalid_use_of_protected_member
      expect((state as dynamic).wantKeepAlive, isTrue);
    });
  });

  group('StreakWeekRow celebration', () {
    testWidgets('a newly completed day bursts exactly 5 particles',
        (tester) async {
      var week = List<bool>.filled(7, false);
      late StateSetter update;
      await tester.pumpWidget(_app(
        StatefulBuilder(builder: (context, setState) {
          update = setState;
          return StreakWeekRow(weekRead: week);
        }),
      ));

      update(() => week = [true, ...week.skip(1)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byWidgetPredicate(_isParticle), findsNWidgets(5));

      await tester.pump(const Duration(milliseconds: 800));
    });
  });
}
