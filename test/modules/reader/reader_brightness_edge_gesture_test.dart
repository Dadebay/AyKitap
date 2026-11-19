import 'package:aykitap/modules/reader/widgets/reader_brightness_edge_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('left middle long press and upward drag raises brightness',
      (tester) async {
    final values = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ReaderBrightnessEdgeGesture(
            brightness: 0.4,
            isDarkPage: true,
            onChanged: values.add,
          ),
        ),
      ),
    ));

    final rect = tester.getRect(find.byType(ReaderBrightnessEdgeGesture));
    final start = Offset(rect.left + 12, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveBy(const Offset(0, -88));
    await tester.pump();
    expect(values.last, greaterThan(0.4));
    expect(find.text('80%'), findsOneWidget);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('80%'), findsNothing);
  });

  testWidgets('a quick page swipe does not change brightness', (tester) async {
    final values = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ReaderBrightnessEdgeGesture(
            brightness: 0.4,
            isDarkPage: true,
            onChanged: values.add,
          ),
        ),
      ),
    ));
    final rect = tester.getRect(find.byType(ReaderBrightnessEdgeGesture));
    final gesture =
        await tester.startGesture(Offset(rect.left + 12, rect.center.dy));
    await gesture.moveBy(const Offset(0, -88));
    await gesture.up();
    await tester.pump();
    expect(values, isEmpty);
  });
}
