import 'package:aykitap/modules/reader/utils/cbz_scroll_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The CBZ reader's scroll mode rests on one assumption: the heights
/// [CbzScrollMetrics] computes are exactly the heights the ListView lays its
/// items out at. If those ever drift, `pageAt(offset)` reports the wrong page
/// and every jump (scrubber, bookmark, go-to-page, restoring position) lands
/// somewhere else — so this pins the two together rather than trusting them to
/// agree. It mirrors the real widget's construction (`itemExtentBuilder` fed
/// from the same metrics) with coloured boxes standing in for the page images.
void main() {
  const width = 400.0;
  const height = 800.0;
  // Pages 0 and 2 are twice as tall as wide; page 1 is square — deliberately
  // uneven, so a bug that assumes a uniform extent shows up.
  const ratios = <double>[0.5, 1.0, 0.5, 0.5];

  late CbzScrollMetrics metrics;
  late ScrollController controller;

  Future<void> pump(WidgetTester tester) async {
    metrics = CbzScrollMetrics(aspectRatios: ratios, viewportWidth: width);
    controller = ScrollController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: ratios.length,
            itemExtentBuilder: (i, _) => metrics.heightOf(i),
            itemBuilder: (_, i) => SizedBox(key: ValueKey('page_$i')),
          ),
        ),
      ),
    );
  }

  testWidgets('ListView lays each page out at exactly its metrics height', (tester) async {
    await pump(tester);
    // Page 0: 400/0.5 = 800 tall, so it exactly fills the viewport.
    expect(tester.getSize(find.byKey(const ValueKey('page_0'))).height, metrics.heightOf(0));
    expect(tester.getSize(find.byKey(const ValueKey('page_0'))).height, 800);
    // Page 1 is square: 400 tall.
    expect(metrics.heightOf(1), 400);
  });

  testWidgets('jumping to offsetOf(i) puts page i at the top of the viewport', (tester) async {
    await pump(tester);
    for (var i = 0; i < ratios.length; i++) {
      controller.jumpTo(metrics.offsetOf(i));
      await tester.pump();
      final top = tester.getTopLeft(find.byKey(ValueKey('page_$i'))).dy;
      expect(top, moreOrLessEquals(0, epsilon: 0.5), reason: 'page $i should sit at the top');
      // ...and the reader would report that same page back from the offset.
      expect(metrics.pageAt(controller.offset), i, reason: 'page $i reported from offset');
    }
  });

  testWidgets('scrolling through the book reports pages in order', (tester) async {
    await pump(tester);
    final seen = <int>[];
    for (var offset = 0.0; offset <= metrics.totalHeight - height; offset += 50) {
      controller.jumpTo(offset);
      await tester.pump();
      final page = metrics.pageAt(controller.offset);
      if (seen.isEmpty || seen.last != page) seen.add(page);
    }
    // Never skips or goes backwards while scrolling forwards. The last stop
    // (offset 2000) is exactly page 3's top edge — 800 + 400 + 800 — so all
    // four pages are reached.
    expect(seen, [0, 1, 2, 3]);
  });
}
