import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aykitap/modules/reader/widgets/pdf_margin_crop_box.dart';

/// The margin trim is pure geometry — it hands the PDF viewer a wider
/// viewport than the real one and clips the overflow — so it can be checked
/// without a PDF, using a plain child in place of the viewer.
void main() {
  // Comfortably inside the 800x600 default test surface, so the box under
  // test is what constrains the child rather than the surface being what
  // constrains the box.
  const viewport = Size(400, 500);

  Future<Size> childSize(WidgetTester tester, double fraction) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: PdfMarginCropBox(
              fraction: fraction,
              child: SizedBox.expand(key: key),
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byKey(key));
  }

  group('PdfMarginCropBox', () {
    testWidgets(
        'lays the page out wide enough to lose the asked-for margin '
        'off each side', (tester) async {
      // 5% off each side leaves the middle 90% filling the viewport, so the
      // page has to be laid out 1/0.9 as wide as the viewport is.
      final size = await childSize(tester, 0.05);
      expect(size.width, closeTo(viewport.width / 0.9, 0.01));

      // Which is to say: exactly 5% of the *page* now hangs off each edge —
      // the fraction is of the page's own width, which is what a margin is
      // naturally measured against. Against the viewport it reads larger.
      final overhang = (size.width - viewport.width) / 2;
      expect(overhang / size.width, closeTo(0.05, 0.0001));
      expect(overhang / viewport.width, closeTo(0.05 / 0.9, 0.0001));
    });

    testWidgets('leaves the page untouched at zero', (tester) async {
      final size = await childSize(tester, 0.0);
      expect(size.width, viewport.width);
    });

    testWidgets(
        'never crops further than maxFraction, however far the '
        'slider is pushed', (tester) async {
      final atMax = await childSize(tester, PdfMarginCropBox.maxFraction);
      final pastMax = await childSize(tester, 0.9);
      expect(pastMax.width, atMax.width);
    });

    testWidgets('only touches the width — the page keeps its full height',
        (tester) async {
      final size = await childSize(tester, 0.08);
      expect(size.height, viewport.height);
    });
  });
}
