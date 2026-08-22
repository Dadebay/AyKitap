part of 'cbz_reader_screen.dart';

/// Bottom-sheet flows this screen opens: settings, bookmarks and "go to
/// page" — pure UI flow, kept separate from the state-mutating actions they
/// call into (see cbz_reader_screen_actions.dart).
extension _CbzReaderScreenSheets on _CbzReaderScreenState {
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => CbzSettingsSheet(
          darkGutter: _darkGutter,
          brightness: _brightness,
          eyeCare: _eyeCare,
          fit: _fit,
          viewMode: _viewMode,
          onGutterChanged: (v) async {
            await _setGutter(v);
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
            final page = int.tryParse(b.cfi.replaceFirst('page:', ''));
            if (page != null && page < _totalPages) _goToPage(page);
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
    if (page != null) _goToPage(page - 1);
  }
}
