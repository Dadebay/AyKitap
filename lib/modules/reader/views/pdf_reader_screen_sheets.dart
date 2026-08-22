part of 'pdf_reader_screen.dart';

/// Bottom-sheet flows this screen opens: settings, bookmarks and "go to
/// page". Kept separate from the state-mutating actions they call into (see
/// pdf_reader_screen_actions.dart) since these are pure UI flow — building
/// and awaiting a sheet — rather than state changes of their own.
extension _PdfReaderScreenSheets on _PdfReaderScreenState {
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // The sheet holds its own copy of nothing — it reads these values each
      // rebuild, so a StatefulBuilder keeps its controls live as they change.
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => PdfSettingsSheet(
          colorMode: _colorMode,
          brightness: _brightness,
          eyeCare: _eyeCare,
          fitPolicy: _fitPolicy,
          viewMode: _viewMode,
          onColorModeChanged: (v) async {
            await _setColorMode(v);
            setSheetState(() {});
          },
          onBrightnessChanged: (v) async {
            await _setBrightness(v);
            setSheetState(() {});
          },
          onEyeCareChanged: (v) async {
            await _setEyeCare(v);
            setSheetState(() {});
          },
          onFitChanged: (v) async {
            await _setFit(v);
            setSheetState(() {});
          },
          onViewModeChanged: (v) async {
            await _setViewMode(v);
            setSheetState(() {});
          },
          // Always offered: whether this PDF *can* reflow isn't known until
          // it's actually converted, and that conversion no longer happens
          // on open — [PdfOpeningScreen] does it on demand after this route
          // is replaced, and reports back if the book turns out to be
          // image-only.
          onSwitchToTextView: _switchToTextView,
        ),
      ),
    );
  }

  void _openBookmarks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => PdfBookmarksSheet(
          bookmarks: BookmarksStore.instance.forBook(_bookId),
          isCurrentPageBookmarked: _isCurrentPageBookmarked,
          onToggleCurrent: () async {
            await _toggleBookmark();
            setSheetState(() {});
          },
          onJump: (b) {
            // `page:N` stores a 0-based index — see [_pageKey].
            final page = int.tryParse(b.cfi.replaceFirst('page:', ''));
            if (page != null) _goToPage(page);
          },
          onRemove: (id) async {
            await BookmarksStore.instance.remove(id);
            if (mounted) _setState(() {});
            setSheetState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _openGoToPage() async {
    if (_totalPages <= 0) return;
    final page = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PdfGoToPageSheet(
          currentPage: _currentPage + 1, totalPages: _totalPages),
    );
    // The sheet speaks in 1-based page numbers, this screen in 0-based indices.
    if (page != null) _goToPage(page - 1);
  }
}
