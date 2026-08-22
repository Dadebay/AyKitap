part of 'cbz_reader_screen.dart';

/// This screen's widget tree: the page viewer (paged or continuous scroll —
/// see cbz_reader_screen_scroll.dart), its washes/loading/error states, and
/// the chrome around it (top bar, bottom bar, focus-mode page indicator).
extension _CbzReaderScreenBody on _CbzReaderScreenState {
  Widget _buildBody(BuildContext context) {
    final bg = _darkGutter ? const Color(0xFF1C1C1E) : Colors.white;
    final inFocus = !_showControls && !_isLoading && _error == null;
    final focusColor = _darkGutter ? Colors.white38 : Colors.black38;
    // Decode target for each page image. Without this, Image.file decodes a
    // scanned page at its native resolution (often 3000-4000px on a side) —
    // full size for every page PageView keeps around (current + neighbours),
    // which is what caused the stutter/OOM on lower-RAM devices. 2x the
    // screen's physical pixels leaves headroom for InteractiveViewer's
    // maxScale: 4 zoom without needing a re-decode.
    final pageCacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context) *
            2)
        .round();

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (_error == null && !_isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: _viewMode == CbzViewMode.scroll
                    ? _buildScrollPages(bg, pageCacheWidth)
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _totalPages,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (_, i) => ColoredBox(
                          color: bg,
                          child: InteractiveViewer(
                            maxScale: 4,
                            child: Center(
                              child: Image.file(File(_pagePaths[i]),
                                  fit: _fit, cacheWidth: pageCacheWidth),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

          // ── Eye-care (blue-light) wash ─────────────────────────────────
          // A warm amber layer over the page, independent of the gutter colour
          // so it works on a light or dark gutter alike. Shared with the
          // EPUB/PDF readers via the same pref.
          if (readerEyeCareColor(_eyeCare, isDarkPage: _darkGutter) != null &&
              _error == null &&
              !_isLoading)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                    color:
                        readerEyeCareColor(_eyeCare, isDarkPage: _darkGutter)!),
              ),
            ),

          if (_isLoading)
            ReaderLoadingOverlay(
                backgroundColor: bg,
                isDarkSurface: _darkGutter,
                message: ReaderStrings.cbzExtracting),

          if (_error != null)
            ReaderErrorOverlay(
              backgroundColor: bg,
              isDarkSurface: _darkGutter,
              message: ReaderStrings.cbzOpenError(_error!),
            ),

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

          // ── Focus-mode page number ─────────────────────────────────────
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
