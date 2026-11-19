import 'package:aykitap/modules/reader/widgets/reader_chapter_edge_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a long upward swipe rushes once; holding alone does not',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ReaderChapterEdgeGesture(
            onNextChapter: () => calls++,
            isDarkPage: true,
          ),
        ),
      ),
    ));

    final center = tester.getCenter(find.byType(ReaderChapterEdgeGesture));
    final hold = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    expect(calls, 0);
    await hold.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(calls, 0);
    await hold.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(calls, 1);
    await hold.moveBy(const Offset(0, -50));
    await tester.pump();
    expect(calls, 1);
    await hold.up();
    await tester.pump();
  });
}
