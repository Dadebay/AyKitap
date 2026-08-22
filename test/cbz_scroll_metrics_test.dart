import 'package:aykitap/modules/reader/utils/cbz_scroll_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Three 400x800 pages (ratio 0.5) at a 400pt-wide viewport => 800pt each.
  CbzScrollMetrics build({List<double>? ratios, double width = 400, double gap = 0}) =>
      CbzScrollMetrics(
        aspectRatios: ratios ?? const [0.5, 0.5, 0.5],
        viewportWidth: width,
        gap: gap,
      );

  test('lays pages out at viewport width, height from aspect ratio', () {
    final m = build();
    expect(m.pageCount, 3);
    expect(m.heightOf(0), 800);
    expect(m.totalHeight, 2400);
    expect(m.offsetOf(0), 0);
    expect(m.offsetOf(1), 800);
    expect(m.offsetOf(2), 1600);
  });

  test('offset maps back to the page containing it', () {
    final m = build();
    expect(m.pageAt(0), 0);
    expect(m.pageAt(799), 0);
    expect(m.pageAt(800), 1); // exact top edge belongs to the new page
    expect(m.pageAt(801), 1);
    expect(m.pageAt(1600), 2);
    expect(m.pageAt(999999), 2); // past the end clamps to the last page
    expect(m.pageAt(-50), 0); // overscroll at the top
  });

  test('offsetOf and pageAt round-trip for every page', () {
    final m = CbzScrollMetrics(
      aspectRatios: const [0.5, 1.4, 0.7, 0.5, 2.0],
      viewportWidth: 390,
    );
    for (var i = 0; i < m.pageCount; i++) {
      expect(m.pageAt(m.offsetOf(i)), i, reason: 'page $i');
    }
  });

  test('pages of differing ratios each get their own height', () {
    final m = CbzScrollMetrics(aspectRatios: const [1.0, 0.5], viewportWidth: 400);
    expect(m.heightOf(0), 400); // square
    expect(m.heightOf(1), 800); // twice as tall as wide
    expect(m.offsetOf(1), 400);
    expect(m.totalHeight, 1200);
  });

  test('gap is included in each page height', () {
    final m = build(gap: 10);
    expect(m.heightOf(0), 810);
    expect(m.offsetOf(1), 810);
    expect(m.totalHeight, 2430);
  });

  // A page whose header couldn't be read must not collapse the stack or shift
  // every page after it.
  test('bad aspect ratios fall back instead of breaking the layout', () {
    final m = CbzScrollMetrics(
      aspectRatios: const [0.0, -1.0, double.nan, double.infinity, 0.5],
      viewportWidth: 400,
      fallbackAspectRatio: 0.5,
    );
    for (var i = 0; i < m.pageCount; i++) {
      expect(m.heightOf(i), 800, reason: 'page $i');
    }
    expect(m.totalHeight, 4000);
    expect(m.pageAt(m.offsetOf(4)), 4);
  });

  test('empty book is handled', () {
    final m = CbzScrollMetrics(aspectRatios: const [], viewportWidth: 400);
    expect(m.pageCount, 0);
    expect(m.totalHeight, 0);
    expect(m.pageAt(0), 0);
    expect(m.offsetOf(3), 0);
  });

  test('offsetOf clamps an out-of-range saved page', () {
    final m = build();
    expect(m.offsetOf(99), 1600);
    expect(m.offsetOf(-4), 0);
  });
}
