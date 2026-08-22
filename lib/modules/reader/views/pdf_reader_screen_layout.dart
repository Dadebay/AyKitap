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

    final width = pages.fold(0.0, (w, p) => math.max(w, p.width));
    var y = 0.0;
    for (final page in pages) {
      layouts.add(
          Rect.fromLTWH((width - page.width) / 2, y, page.width, page.height));
      y += page.height;
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(width, y));
  }
}
