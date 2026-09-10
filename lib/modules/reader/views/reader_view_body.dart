part of 'reader_view.dart';

/// The screen's top-level widget tree: the WebView viewer layer (see
/// reader_view_epub_viewer.dart), its eye-care wash, the chrome above it
/// (see reader_view_chrome.dart), the opening overlay and the selection
/// toolbar.
extension _ReaderViewBody on _ReaderScreenState {
  Widget _buildScaffold(BuildContext context, ReaderProvider provider) {
    final bgColor = _extractBgColor(provider.currentEpubTheme);
    final isDarkPage = bgColor.computeLuminance() < 0.4;
    // In focus mode (chrome hidden) a faint chapter title / page number
    // stays on screen; they use the page's own contrast colour.
    final focusColor = isDarkPage ? Colors.white38 : Colors.black38;
    final inFocus = !provider.showControls && !provider.isLoading;

    return PopScope(
      // System back gesture/button bypasses ReaderTopBar's onBack, which
      // is the only place progress used to get saved — losing a whole
      // session's progress on a swipe-back. Intercept and route it
      // through the same saveAndClose() path.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await provider.saveAndClose();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        // The add-note sheet's text field autofocuses, so the keyboard
        // opens the instant it appears. Left at the default (true), this
        // Scaffold — still mounted behind that modal — shrank to avoid
        // it too, and epub.js treats a resized viewport as a real
        // layout change: it re-lays-out and re-displays the current
        // location, and on a resize that arrives mid-transition (the
        // keyboard's own slide-up animation firing several in a row)
        // that redisplay can land on the *section's* start rather than
        // the exact page — which for anyone still in the book's first
        // chapter reads as being thrown back to page 1 just for adding a
        // highlight. The sheet already pads its own content for the
        // keyboard, so the reader behind it never needs to move.
        resizeToAvoidBottomInset: false,

        // The bars are *overlays*, not Scaffold appBar/bottomNavigationBar.
        // As slots they resized the body every time they toggled, which
        // resized the WebView and made epub.js repaginate — that's what
        // broke swiping to turn pages while the controls were on screen.
        // Floating them over a fixed-size viewer keeps pagination stable.
        body: Stack(
          children: [
            // ── EPUB Viewer ────────────────────────────────────────────
            // Brightness (TZ §12.4) now dims the *device* screen via
            // [ReaderProvider.setBrightness] rather than painting a black
            // veil over the page — the veil greyed out the text.
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: _ReaderScreenState._viewerInset,
                  // Measures the gesture in the *screen's* coordinate frame,
                  // which the WebView's own touch coordinates can't do while
                  // a page transition is animating the iframe underneath the
                  // finger — see [ReaderTapGate]. Translucent so every event
                  // still reaches the viewer itself.
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) => _tapGate.pointerDown(e.position),
                    onPointerMove: (e) => _tapGate.pointerMove(e.position),
                    onPointerUp: (e) => _tapGate.pointerUp(e.position),
                    onPointerCancel: (_) => _tapGate.pointerCancel(),
                    child: provider.loadFailed
                        ? EpubErrorView(
                            bgColor: bgColor, isDarkPage: isDarkPage)
                        : _buildEpubViewer(provider),
                  ),
                ),
              ),
            ),

            // ── Eye-care (blue-light) wash ─────────────────────────────
            // A warm amber layer over the page, independent of the reader
            // theme so it works on a light or dark page alike. IgnorePointer
            // keeps taps/swipes flowing through to the WebView underneath.
            if (readerEyeCareColor(provider.eyeCare, isDarkPage: isDarkPage) !=
                null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                      color: readerEyeCareColor(provider.eyeCare,
                          isDarkPage: isDarkPage)!),
                ),
              ),

            _buildChrome(context, provider, bgColor, focusColor, inFocus),

            // ── Loading overlay ────────────────────────────────────────
            if (_showLoadingOverlay)
              BookOpeningOverlay(
                bgColor: bgColor,
                loaded: !provider.isLoading,
                onDone: () {
                  if (mounted) _setState(() => _showLoadingOverlay = false);
                },
              ),

            // ── Selection toolbar (TZ §12.7) ───────────────────────────
            if (provider.hasSelection)
              SelectionToolbar(
                selectedText: provider.selectedText,
                selectionRect: provider.selectionRect,
                // Every book can be annotated now — imported files just
                // won't offer "go to book" on the saved note (no catalogue
                // entry to open); see NoteCard.
                canAnnotate: true,
                isExistingHighlight: provider.selectedHighlight != null,
                onAddNote: () => _addNote(context, provider),
                onRemoveHighlight: () => _removeHighlight(context, provider),
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: provider.selectedText));
                  provider.clearSelection();
                  _showSnack(context, ReaderStrings.copiedMessage);
                },
                onShare: () {
                  final text = provider.selectedText;
                  provider.clearSelection();
                  if (text.isNotEmpty) Share.share(text);
                },
                onClose: provider.clearSelection,
              ),
          ],
        ),
      ),
    );
  }

  Color _extractBgColor(EpubTheme theme) {
    final dec = theme.backgroundDecoration;
    if (dec is BoxDecoration) return dec.color ?? Colors.white;
    return Colors.white;
  }
}
