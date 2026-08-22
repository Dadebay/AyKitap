part of 'reader_view.dart';

/// The [EpubViewer] itself and the touch handling wired to it — the WebView
/// consumes touch events, so the reader chrome's tap-to-toggle can only
/// reach the gesture through the callbacks sakura_epub forwards out of the
/// page, not a Flutter [GestureDetector].
extension _ReaderViewEpubViewer on _ReaderScreenState {
  Widget _buildEpubViewer(ReaderProvider provider) {
    // No GestureDetector here: the EPUB renders inside a WebView, which
    // consumes touch events, so a Flutter tap handler wrapped around it never
    // fires — that's why the top/bottom bars could never be revealed. Instead
    // we use the touch callbacks sakura_epub forwards out of the page.
    return EpubViewer(
      epubController: provider.epubController,
      epubSource: EpubSource.fromFile(File(widget.bookPath)),
      // Opens the WebView directly at the saved position — see
      // ReaderProvider.savedCfi for why this replaced a post-load progress
      // jump that raced book.locations.generate() on large books.
      initialCfi: provider.savedCfi.isEmpty ? null : provider.savedCfi,
      // Skips epub.js's multi-second locations scan on reopen — see
      // ReaderProvider.savedLocationsJson.
      initialLocations: provider.savedLocationsJson,
      onLocationsGenerated: provider.onLocationsGenerated,
      displaySettings: EpubDisplaySettings(
        flow: EpubFlow.paginated,
        snap: true,
        // One column of text, whatever the screen's width. The default is
        // EpubSpread.auto, which is what put the book into a two-page spread
        // as soon as the reader was rotated (epub.js sets divisor = 2 once the
        // viewport is wider than its minSpreadWidth) — a book split down the
        // middle into two narrow columns, rather than the single full-width
        // column that landscape is being used for in the first place.
        // 'none' pins epub.js's divisor to 1, so rotating just makes the one
        // column wider.
        spread: EpubSpread.none,
        theme: provider.currentEpubTheme,
        // sakura_epub applies this as `${fontSize}px`, while the provider keeps
        // it as a double for its slider — round on the way in. This only seeds
        // the initial load; ReaderProvider.onEpubLoaded re-applies the saved
        // size once the rendition exists.
        fontSize: provider.fontSize.round(),
      ),
      // TZ §12.7: our own selection toolbar (Belle / Not / Kopyala / Paýlaş)
      // is the only menu we want — suppress the WebView's native Android/iOS
      // one so it doesn't show a second, duplicate toolbar over the selection.
      suppressNativeContextMenu: true,
      // Prokrutka is the one mode that moves *down* the book, so it's the one
      // mode whose page turn hangs off a vertical flick. Android reads the
      // mode straight out of epubView.js; iOS runs its own detector, which
      // needs telling.
      verticalPageNavigation:
          provider.pageTransition == ReaderPageTransition.scroll,
      // Tapping an already-painted highlight re-selects its exact range
      // instead of doing nothing — see ReaderProvider.selectedHighlight and
      // _removeHighlight, which together are the only way to undo a
      // highlight once it's been made.
      selectAnnotationRange: true,
      onEpubLoaded: provider.onEpubLoaded,
      onEpubLoadFailed: provider.onEpubLoadFailed,
      onChaptersLoaded: provider.onChaptersLoaded,
      onRelocated: provider.onRelocated,
      onTextSelected: provider.onTextSelected,
      onSelection: provider.onSelection,
      onDeselection: provider.onDeselection,
      onTouchDown: (x, y) {
        _touchStart = Offset(x, y);
        _touchStartAt = DateTime.now();
      },
      onTouchUp: (x, y) => _onTouchUp(provider, x, y),
    );
  }

  /// Toggles the reader chrome on a genuine tap. Coordinates arrive
  /// normalised (0–1). Swipes (page turns) and long presses (text selection)
  /// are filtered out so they don't flash the bars on every page change.
  void _onTouchUp(ReaderProvider provider, double x, double y) {
    final start = _touchStart;
    final startedAt = _touchStartAt;
    _touchStart = null;
    _touchStartAt = null;
    if (start == null || startedAt == null) return;

    final moved = (Offset(x, y) - start).distance;
    final held = DateTime.now().difference(startedAt);
    if (moved > 0.03 || held > const Duration(milliseconds: 300)) return;

    if (provider.hasSelection) {
      provider.clearSelection();
    } else {
      provider.toggleControls();
    }
  }

  /// The focus-mode page indicator: "12 / 340".
  ///
  /// The epub engine counts the book's pages a few seconds after it opens (see
  /// [EpubLocation.page]); until it reports them, this falls back to a page
  /// estimated from the catalogue's page count, and to a bare percentage for
  /// imported files that have no catalogue entry.
  String _pageLabel(ReaderProvider provider) {
    if (provider.totalPages > 0) {
      return '${provider.currentPage} / ${provider.totalPages}';
    }
    final p = provider.progress.clamp(0.0, 1.0);
    final total = widget.bookPages;
    if (total != null && total > 0) {
      return '${(p * total).round().clamp(1, total)} / $total';
    }
    return '${(p * 100).round()}%';
  }
}
