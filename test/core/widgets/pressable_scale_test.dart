import 'package:aykitap/core/theme/app_motion.dart';
import 'package:aykitap/core/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

// `Matrix4.getMaxScaleOnAxis()` takes the max across X/Y/*and Z*, and
// `Transform.scale` never touches Z (it stays 1.0) — so for any down-scale
// (pressedScale < 1) that method always reports 1.0 regardless of the
// actual scale. Reading the X-scale entry directly avoids that trap.
double _scaleOf(WidgetTester tester) => tester
    .widget<Transform>(find
        .descendant(
            of: find.byType(PressableScale), matching: find.byType(Transform))
        .first)
    .transform
    .entry(0, 0);

void main() {
  group('PressableScale', () {
    testWidgets('scales down to 0.96 on press and back to 1.0 on release',
        (tester) async {
      await tester.pumpWidget(_app(
        PressableScale(onTap: () {}, child: const Text('Book')),
      ));

      final center = tester.getCenter(find.text('Book'));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(AppMotion.pressDown);
      expect(_scaleOf(tester), closeTo(0.96, 0.001));

      await gesture.up();
      await tester.pump();
      await tester.pump(AppMotion.pressRelease);
      expect(_scaleOf(tester), closeTo(1.0, 0.001));
    });

    testWidgets('a scroll drag cancels the press instead of completing it',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_app(
        PressableScale(onTap: () => tapped = true, child: const Text('Book')),
      ));

      final center = tester.getCenter(find.text('Book'));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 20));
      // A drag well past the touch slop loses the tap gesture arena — the
      // same thing a horizontal shelf's scroll does to a card underneath it.
      await gesture.moveBy(const Offset(0, 60));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(_scaleOf(tester), closeTo(1.0, 0.001));
    });

    testWidgets('reduce motion disables the scale entirely', (tester) async {
      await tester.pumpWidget(_app(
        PressableScale(onTap: () {}, child: const Text('Book')),
        reduceMotion: true,
      ));

      final center = tester.getCenter(find.text('Book'));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_scaleOf(tester), 1.0);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('onLongPress fires independently of onTap', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(_app(
        PressableScale(
          onTap: () {},
          onLongPress: () => longPressed = true,
          child: const Text('Book'),
        ),
      ));

      await tester.longPress(find.text('Book'));
      expect(longPressed, isTrue);
    });
  });
}
