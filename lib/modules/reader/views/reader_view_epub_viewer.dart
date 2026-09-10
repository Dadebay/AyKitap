part of 'reader_view.dart';

/// The [EpubViewer] itself and the touch handling wired to it — the WebView
/// consumes touch events, so the reader chrome's tap-to-toggle can only
/// reach the gesture through the callbacks sakura_epub forwards out of the
/// page, not a Flutter [GestureDetector].
extension _ReaderViewEpubViewer on _ReaderScreenState {
  Widget _buildEpubViewer(ReaderProvider provider) {
    // Temporary diagnostic for the "kicked out on the loading screen" crash
    // report — see PdfOpeningScreen._resolve's comment. A native WebView
    // renderer crash on a bad/huge EPUB kills the process before this
    // widget's own onEpubLoadFailed ever gets a chance to fire, so this is
    // the last line that would print before it.
    final file = File(widget.bookPath);
    log('🔍 [BookOpen] building EpubViewer bookId=${widget.bookId} '
        'exists=${file.existsSync()} '
        'sizeBytes=${file.existsSync() ? file.lengthSync() : -1}');
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
        // epub.js's own default is EpubSpread.auto, which is what used to put
        // the book into a two-page spread as soon as the reader was rotated
        // (epub.js sets divisor = 2 once the viewport is wider than its
        // minSpreadWidth) — a book split down the middle into two narrow
        // columns, rather than the single wider column landscape is meant to
        // give a fixed-width page. So spread is never left to epub.js's own
        // heuristic; it's driven entirely by ReaderProviderLayout instead,
        // which turns it on only for a genuinely wide window or an actual
        // foldable hinge — a plain rotated phone stays single-column exactly
        // as before. [ReaderProvider.isSpreadActive] is already correct by
        // this build (this screen's `didChangeDependencies` runs before its
        // first `build`), so the book opens directly in the right layout
        // rather than opening single-column and visibly relayouting once
        // `onEpubLoaded` fires.
        spread: provider.isSpreadActive ? EpubSpread.always : EpubSpread.none,
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
      onTouchDown: _tapGate.webTouchDown,
      onTouchUp: (x, y) => _onTouchUp(provider, x, y),
    );
  }

  /// Toggles the reader chrome on a genuine tap. Swipes (scrolls and page
  /// turns) and long presses (text selection) are filtered out by
  /// [ReaderTapGate] so they don't flip the bars on every page change — see
  /// that class for why the WebView's own coordinates can't decide this
  /// alone.
  void _onTouchUp(ReaderProvider provider, double x, double y) {
    final isTap = _tapGate.webTouchUpIsTap(
      x,
      y,
      lastRelocationAt: provider.lastRelocationAt,
    );
    if (!isTap) return;

    if (provider.hasSelection) {
      provider.clearSelection();
    } else {
      provider.toggleControls();
    }
  }

  /// The focus-mode position indicator: "%12".
  ///
  /// A percentage rather than "page / total" for the same reason the bottom
  /// bar's scrubber shows one — see [ReaderProgressScrubber]. An EPUB's page
  /// numbers are derived from how much text a screen currently holds, so the
  /// same spot in the same book reads differently between sessions; the
  /// percentage comes from epub.js's locations and doesn't move.
  String _pageLabel(ReaderProgressSnapshot snapshot) =>
      '%${(snapshot.progress.clamp(0.0, 1.0) * 100).round()}';
}
