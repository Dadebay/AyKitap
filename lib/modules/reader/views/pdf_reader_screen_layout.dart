part of 'pdf_reader_screen.dart';

/// The width [_PdfReaderScreenLayout._layoutPages] normalises every page to:
/// the *median* page width, not the widest one.
///
/// This number decides both how sharply the book is drawn and how much of the
/// screen a page fills, which is why it can't be left to whichever page
/// happens to be biggest.
///
/// pdfrx rasterises a page from its **source** size at
/// `zoom × devicePixelRatio` (its own `_paintPages`), and the zoom is whatever
/// fits the laid-out page into the viewport (`alternativeFitScale` in pdfrx's
/// legacy size delegate, computed from the page's own layout rect). So a
/// column wider than the book really is scales the zoom down and every page
/// renders at a fraction of the resolution it is then stretched across.
///
/// Taking the maximum handed that decision to a single page. One 994-page
/// book — 992 pages of 419pt text, one 1414pt insert, one 96pt cover — laid
/// out at 1414: in scroll mode the ordinary pages rasterised at roughly a
/// third of their displayed size (soft text, and a steady stream of
/// higher-resolution re-renders while scrolling, which reads as stuttering),
/// and in paged mode each page sat marooned in the middle of a slot three
/// times its size.
///
/// The median is what the book actually is. An outlier — a wide insert, a
/// thumbnail-sized cover — is fitted to that column like any other page
/// instead of dragging the other 993 with it.
@visibleForTesting
double pdfLayoutColumnWidth(Iterable<double> pageWidths) {
  final widths = pageWidths.toList()..sort();
  if (widths.isEmpty) return 0;
  return widths[widths.length ~/ 2];
}

/// Which of pdfrx's two fit zooms the viewer should open at.
///
/// [coverZoom] scales to the document's whole laid-out bounding box, so what
/// it ends up fitting depends entirely on the shape of that box:
///
/// * Scroll mode stacks pages into one tall, narrow column, so covering it
///   collapses to fitting the **width** — which is what a reader wants.
/// * Paged mode lays 994 pages out side by side, making the box enormously
///   *wide*, so covering it collapses to fitting the **height** — a zoom
///   computed from how tall one page is against a strip thousands of pages
///   long. On this book that came out at ~1.17: the page overflowed the
///   screen left and right, and since it was then drawn larger than the
///   resolution it had been rasterised at, it looked blurred as well. The
///   reader only met it on reopening, because that is when the initial zoom
///   is applied.
///
/// So paged mode never covers; it fits the page. That is also the only zoom
/// it can safely use, because paged mode locks panning to the horizontal
/// axis — anything taller than the viewport would have a bottom edge the
/// reader cannot reach.
@visibleForTesting
double pdfInitialZoom({
  required PdfViewMode viewMode,
  required double fitPageZoom,
  required double coverZoom,
}) =>
    viewMode == PdfViewMode.scroll ? coverZoom : fitPageZoom;

/// The page-layout algorithm fed to [PdfViewer.file] — kept separate from
/// the rest of the widget tree since it's pure geometry, not anything drawn
/// directly.
extension _PdfReaderScreenLayout on _PdfReaderScreenState {
  /// Lays the document out for the current [_viewMode].
  ///
  /// Both modes normalise every page to one column width (see
  /// [pdfLayoutColumnWidth]), preserving each page's own aspect ratio. That is
  /// what makes a page fill the screen instead of floating in the middle of
  /// it: pdfrx fits the *page's layout rect* to the viewport, so a rect that
  /// is only part of the laid-out slot is only part of the screen.
  ///
  /// * [PdfViewMode.paged] — pages side by side with a gutter between them,
  ///   each vertically centred so they don't jump up and down as the reader
  ///   swipes through pages of slightly different heights.
  /// * [PdfViewMode.scroll] — pages stacked vertically with **no** gap, so
  ///   they run together as one continuous strip. That seamlessness is the
  ///   whole point for a webtoon/manhwa PDF, where a visible gap every screen
  ///   reads as a border printed on the picture.
  PdfPageLayout _layoutPages(List<PdfPage> pages, PdfViewerParams params) {
    final paged = _viewMode == PdfViewMode.paged;
    final gap = paged ? params.margin : 0.0;
    final layouts = <Rect>[];

    final width = pdfLayoutColumnWidth(pages.map((p) => p.width));
    // Each page's height once scaled to [width]. A book's pages aren't always
    // uniform — a wide promo/cover insert next to normal-sized chapter pages,
    // say — and both modes pick one zoom for the whole document, so leaving
    // pages at their native width under that one zoom is what left the
    // narrower ones short of the screen edges.
    final heights = [
      for (final page in pages) page.height * (width / page.width)
    ];

    if (paged) {
      final tallest = heights.fold(0.0, math.max);
      var x = gap;
      for (var i = 0; i < pages.length; i++) {
        layouts.add(Rect.fromLTWH(
            x, gap + (tallest - heights[i]) / 2, width, heights[i]));
        x += width + gap;
      }
      return PdfPageLayout(
          pageLayouts: layouts, documentSize: Size(x, tallest + gap * 2));
    }

    var y = 0.0;
    for (var i = 0; i < pages.length; i++) {
      layouts.add(Rect.fromLTWH(0, y, width, heights[i]));
      y += heights[i];
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(width, y));
  }
}
