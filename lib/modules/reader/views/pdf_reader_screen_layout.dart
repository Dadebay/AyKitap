part of 'pdf_reader_screen.dart';

/// The page-layout algorithm fed to [PdfViewer.file] — kept separate from
/// the rest of the widget tree since it's pure geometry, not anything drawn
/// directly.
extension _PdfReaderScreenLayout on _PdfReaderScreenState {
  /// Lays the document out for the current [_viewMode].
  ///
  /// * [PdfViewMode.paged] — pages side by side, each centred in a slot as
  ///   wide as the widest page, with a gutter between them. Each page keeps
  ///   its own size, so a book carrying oversized inserts (promo pages
  ///   appended at a different page size) doesn't shrink its normal pages to
  ///   match them.
  /// * [PdfViewMode.scroll] — pages stacked vertically with **no** gap, so
  ///   they run together as one continuous strip. That seamlessness is the
  ///   whole point for a webtoon/manhwa PDF, where a visible gap every screen
  ///   reads as a border printed on the picture.
  PdfPageLayout _layoutPages(List<PdfPage> pages, PdfViewerParams params) {
    final paged = _viewMode == PdfViewMode.paged;
    final gap = paged ? params.margin : 0.0;
    final layouts = <Rect>[];

    if (paged) {
      final slot = pages.fold(0.0, (w, p) => math.max(w, p.width));
      final tallest = pages.fold(0.0, (h, p) => math.max(h, p.height));
      var x = gap;
      for (final page in pages) {
        layouts.add(Rect.fromLTWH(
          x + (slot - page.width) / 2,
          gap + (tallest - page.height) / 2,
          page.width,
          page.height,
        ));
        x += slot + gap;
      }
      return PdfPageLayout(
          pageLayouts: layouts, documentSize: Size(x, tallest + gap * 2));
    }

    // Every page is stretched to the same [width] (preserving its own aspect
    // ratio) rather than kept at its native size like paged mode does above.
    // A book's pages aren't always uniform — a wide promo/cover insert next
    // to normal-sized chapter pages, say — and scroll mode picks one zoom for
    // the whole document; leaving pages at their native width under that one
    // zoom is what made the narrower ones render short of the screen edges
    // instead of filling it like the wide one does.
    final width = pages.fold(0.0, (w, p) => math.max(w, p.width));
    var y = 0.0;
    for (final page in pages) {
      final height = page.height * (width / page.width);
      layouts.add(Rect.fromLTWH(0, y, width, height));
      y += height;
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(width, y));
  }
}
