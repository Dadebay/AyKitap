part of 'cbz_reader_screen.dart';

/// [CbzViewMode.scroll]'s continuous list — kept separate from the rest of
/// the widget tree since it owns its own layout algorithm ([CbzScrollMetrics])
/// on top of just drawing pages.
extension _CbzReaderScreenScroll on _CbzReaderScreenState {
  /// [CbzViewMode.scroll] — every page stacked in one continuous scroll, each
  /// drawn at the full viewport width so a tall comic page stays legible and
  /// you scroll down it, rather than the whole page being shrunk to fit.
  ///
  /// Heights come from [CbzScrollMetrics] rather than from the images
  /// themselves: a plain `Image.file` in a ListView only knows its height once
  /// the file has been decoded, so the list would grow and jump under the
  /// reader as pages stream in — and the scroll offset that tracks the current
  /// page would jump with it. Sizing each slot up front from the page's known
  /// aspect ratio keeps the list stable and makes offset ↔ page exact.
  ///
  /// No InteractiveViewer here: pinch-zoom inside a vertical list fights the
  /// scroll gesture, and a page already filling the width is what the zoom was
  /// for in paged mode.
  Widget _buildScrollPages(Color bg, int pageCacheWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (_metrics == null || _metricsWidth != width) {
          _metrics = CbzScrollMetrics(
              aspectRatios: _aspectRatios, viewportWidth: width);
          _metricsWidth = width;
        }
        final metrics = _metrics!;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
              final page = metrics.pageAt(_scrollController.offset);
              if (page != _currentPage) _onPageChanged(page);
            }
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _totalPages,
            // Every slot's height is already known, so the viewport can lay
            // out without measuring children.
            itemExtentBuilder: (i, _) => metrics.heightOf(i),
            itemBuilder: (_, i) => ColoredBox(
              color: bg,
              child: Image.file(
                File(_pagePaths[i]),
                fit: BoxFit.fitWidth,
                width: width,
                cacheWidth: pageCacheWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}
