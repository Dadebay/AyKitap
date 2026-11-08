part of 'pdf_reader_screen.dart';

/// This screen's top-level widget tree: the page layer (see
/// pdf_reader_screen_page_layer.dart) plus the chrome around it — top bar,
/// bottom bar and the focus-mode page indicator.
extension _PdfReaderScreenBody on _PdfReaderScreenState {
  Widget _buildBody(BuildContext context) {
    // Gutter behind the page, and whether this mode reads as a dark surface
    // (drives the tint of the focus page-number, loading and error text).
    final bg = switch (_colorMode) {
      PdfColorMode.light => Colors.white,
      PdfColorMode.sepia => const Color(0xFFEADFC6),
      PdfColorMode.night => const Color(0xFF1C1C1E),
    };
    final isDarkSurface = _colorMode == PdfColorMode.night;
    final nightMode = _colorMode == PdfColorMode.night;
    final inFocus = !_showControls && !_isLoading && _error == null;
    final focusColor = isDarkSurface ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildPageLayer(bg, isDarkSurface, nightMode)),

          // ── Top bar ────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ReaderTopBar(
                    title: widget.title,
                    isBookmarked: _isCurrentPageBookmarked,
                    pageColor: bg,
                    eyeCare: _eyeCare,
                    onBack: () async {
                      final navigator = Navigator.of(context);
                      await _saveProgress();
                      navigator.pop();
                    },
                    onBookmark: _toggleBookmark,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom bar ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showControls,
              child: AnimatedSlide(
                offset: _showControls ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: PdfBottomBar(
                    pageColor: bg,
                    eyeCare: _eyeCare,
                    currentPage: _currentPage + 1,
                    totalPages: _totalPages,
                    progress: _totalPages > 0
                        ? (_currentPage + 1) / _totalPages
                        : 0.0,
                    onProgressChanged: _jumpToProgress,
                    onBookmarks: _openBookmarks,
                    onAddNote: _addNote,
                    onSettings: _openSettings,
                    onGoToPage: _openGoToPage,
                  ),
                ),
              ),
            ),
          ),

          // ── Focus-mode page number (bottom) ────────────────────────────
          ReaderFocusPageIndicator(
            visible: inFocus,
            color: focusColor,
            label: _totalPages > 0 ? '${_currentPage + 1} / $_totalPages' : '',
          ),
        ],
      ),
    );
  }
}
