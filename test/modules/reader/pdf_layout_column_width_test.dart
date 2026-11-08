// The scroll column's width sets the zoom, and pdfrx rasterises every page
// from its source size at that zoom — so one oversized page taken as the
// column width renders the whole book under-resolution and makes scrolling
// stutter. Reported against a 994-page book with a single wide insert.
import 'package:aykitap/modules/reader/views/pdf_reader_screen.dart';
import 'package:aykitap/modules/reader/widgets/pdf_settings_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reported book: 992 pages of ordinary A5 text, one oversized insert,
/// one thumbnail-sized cover.
List<double> get _permanPageWidths =>
    [96.0, 1414.0, ...List.filled(992, 419.0)];

void main() {
  test('a lone oversized insert no longer defines the column', () {
    expect(pdfLayoutColumnWidth(_permanPageWidths), 419.0);
  });

  test('a lone undersized cover does not define it either', () {
    expect(pdfLayoutColumnWidth([96.0, ...List.filled(50, 419.0)]), 419.0);
  });

  test('a uniform book is unaffected', () {
    expect(pdfLayoutColumnWidth(List.filled(200, 595.0)), 595.0);
  });

  test('page order does not change the answer', () {
    final shuffled = [419.0, 1414.0, 419.0, 96.0, 419.0];
    final sorted = [96.0, 419.0, 419.0, 419.0, 1414.0];

    expect(pdfLayoutColumnWidth(shuffled), pdfLayoutColumnWidth(sorted));
  });

  test('a genuinely wide book still gets a wide column', () {
    // Nothing here is an outlier — a webtoon whose pages really are 1414
    // wide must not be shrunk to some narrower page's width.
    expect(pdfLayoutColumnWidth(List.filled(30, 1414.0)), 1414.0);
  });

  test('an empty document is handled rather than throwing', () {
    expect(pdfLayoutColumnWidth(const <double>[]), 0);
  });

  test('a single-page document uses that page', () {
    expect(pdfLayoutColumnWidth(const [612.0]), 612.0);
  });

  group('why this matters: the resulting rasterisation scale', () {
    // pdfrx renders a page at sourceWidth * zoom * devicePixelRatio, with
    // zoom = viewportWidth / columnWidth in scroll mode. A phone viewport of
    // 390 logical px at dpr 3 wants 1170 physical px across.
    const viewport = 390.0;
    const dpr = 3.0;
    const physicalWidth = viewport * dpr;

    double renderedPixelsFor(double sourceWidth, double columnWidth) =>
        sourceWidth * (viewport / columnWidth) * dpr;

    test('an ordinary page now rasterises at the width it is displayed at', () {
      final column = pdfLayoutColumnWidth(_permanPageWidths);

      expect(renderedPixelsFor(419, column), closeTo(physicalWidth, 1));
    });

    test('taking the widest page instead would third that resolution', () {
      final widest = _permanPageWidths.reduce((a, b) => a > b ? a : b);

      expect(renderedPixelsFor(419, widest), lessThan(physicalWidth / 3 + 1));
    });
  });

  group('why this matters: how much screen a paged page fills', () {
    // pdfrx fits a page by its own layout rect, not by the slot it sits in
    // (`alternativeFitScale`, pdf_viewer_size_delegate_legacy.dart). Paged
    // mode used to leave each page at its native width inside a slot as wide
    // as the widest page, so an ordinary page of this book was laid out at
    // 419 inside a 1414 slot and was drawn at under a third of the screen —
    // the "page stranded in the middle" the reader saw.
    const viewport = 390.0;

    /// The fraction of the viewport a page covers when the viewer fits
    /// [slotWidth] but the page itself is only [pageWidth] wide.
    double screenFractionFor({
      required double pageWidth,
      required double slotWidth,
    }) =>
        (pageWidth * (viewport / slotWidth)) / viewport;

    test('a page normalised to the column now fills the width', () {
      final column = pdfLayoutColumnWidth(_permanPageWidths);

      // Normalised, the page *is* the column.
      expect(screenFractionFor(pageWidth: column, slotWidth: column),
          closeTo(1.0, 0.001));
    });

    test('left at its native width in the widest slot it covered under a third',
        () {
      final widest = _permanPageWidths.reduce((a, b) => a > b ? a : b);

      expect(screenFractionFor(pageWidth: 419, slotWidth: widest),
          lessThan(1 / 3));
    });

    test('a uniform book filled the width before and still does', () {
      final column = pdfLayoutColumnWidth(List.filled(200, 595.0));

      expect(screenFractionFor(pageWidth: 595, slotWidth: column),
          closeTo(1.0, 0.001));
    });
  });

  group('which fit the viewer opens at', () {
    // The numbers this book actually produces: 994 pages of 419x595 laid out
    // side by side in paged mode, stacked in one column in scroll mode, in a
    // 390x750 viewport.
    const fitPage = 0.897; // min(390 / 435, 750 / 611)
    const pagedCover = 1.175; // max(390 / 424446, 750 / 638) — fits the height
    const scrollCover = 0.931; // 390 / 419 — a tall column, so fits the width

    test('scroll mode covers, which for a tall column means fitting the width',
        () {
      expect(
        pdfInitialZoom(
          viewMode: PdfViewMode.scroll,
          fitPageZoom: fitPage,
          coverZoom: scrollCover,
        ),
        scrollCover,
      );
    });

    test('paged mode fits the page instead of covering', () {
      expect(
        pdfInitialZoom(
          viewMode: PdfViewMode.paged,
          fitPageZoom: fitPage,
          coverZoom: pagedCover,
        ),
        fitPage,
      );
    });

    test('covering in paged mode is what overflowed the screen', () {
      // The regression: a zoom taken from how tall one page is against a
      // strip 994 pages wide put the page past both edges — and drawn larger
      // than it had been rasterised for, so blurred with it.
      const viewport = 390.0;
      const pageWidthWithMargin = 435.0;

      expect(pageWidthWithMargin * pagedCover, greaterThan(viewport));
      expect(pageWidthWithMargin * fitPage, closeTo(viewport, 1));
    });
  });
}
