part of 'reader_view.dart';

/// The reader's chrome: top bar, bottom bar and the two focus-mode labels
/// that replace them while the chrome is hidden. Split out from
/// reader_view_body.dart, which owns the viewer layer and overlays this
/// sits above.
extension _ReaderViewChrome on _ReaderScreenState {
  Widget _buildChrome(BuildContext context, ReaderProvider provider,
      Color bgColor, Color focusColor, bool inFocus) {
    return Positioned.fill(
      child: Stack(
        children: [
          // ── Top bar (TZ §12.1) ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !provider.showControls,
              child: AnimatedSlide(
                offset:
                    provider.showControls ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: provider.showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ReaderTopBar(
                    // TZ §12.1: the centre shows the *chapter* name; the
                    // book title stands in until a chapter resolves.
                    title: provider.currentChapterTitle ?? widget.bookTitle,
                    isBookmarked: provider.isCurrentPageBookmarked,
                    pageColor: bgColor,
                    eyeCare: provider.eyeCare,
                    onBack: () async {
                      await provider.saveAndClose();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    onBookmark: () => _showBookmarks(context, provider),
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom bar (pill design, TZ §12.3) ─────────────────────
          // Nothing here has meaning once the book failed to load — no
          // pages, chapters or search to offer.
          if (!provider.loadFailed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !provider.showControls,
                child: AnimatedSlide(
                  offset:
                      provider.showControls ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: provider.showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: ReaderBottomBar(
                      progress: provider.progress,
                      currentPage: provider.currentPage,
                      totalPages: provider.totalPages,
                      pageColor: bgColor,
                      eyeCare: provider.eyeCare,
                      onSettings: () => _showSettings(context),
                      onChapters: () => _showChapters(context, provider),
                      onSearch: () => _showSearch(context, provider),
                      onProgressChanged: (value) =>
                          provider.epubController.toProgressPercentage(value),
                    ),
                  ),
                ),
              ),
            ),

          // ── Focus-mode chapter label (top) ─────────────────────────
          // Shown only while the chrome is hidden, so the reader still
          // knows the chapter without bringing the bars back.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: inFocus ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Text(
                      provider.currentChapterTitle ?? widget.bookTitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: focusColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Focus-mode page number (bottom) ────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: inFocus ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Text(
                      _pageLabel(provider),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: focusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
