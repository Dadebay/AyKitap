part of 'reader_provider.dart';

/// Local (`SharedPreferences`) and server (`ReadingProgressReporter`/
/// `LastReadBookStore`) progress persistence, plus [saveAndClose] and the
/// state reset it triggers when a reader screen is popped.
extension ReaderProviderPersistence on ReaderProvider {
  /// CFI the book was at when it was last closed, read once in `initialize`
  /// and handed to `EpubViewer.initialCfi` so the WebView opens directly at
  /// that spot — see [onEpubLoaded] for why this replaced the old
  /// progress-percentage jump.
  String get savedCfi => _savedCfi;

  /// A previously-saved `book.locations.save()` JSON blob (see
  /// [onLocationsGenerated]), read once in `initialize` and handed to
  /// `EpubViewer.initialLocations`. Lets the WebView skip epub.js's
  /// multi-second `book.locations.generate()` scan — without it, the page
  /// count and progress bar sat at 0 for the first few seconds of *every*
  /// open of the same book, not just the first.
  String? get savedLocationsJson => _savedLocationsJson;

  Future<void> _saveProgress() async {
    if (_bookId == null || _isProgressSaving) return;
    _isProgressSaving = true;
    _notify();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('book_${_bookId}_progress', _progress);
      await prefs.setInt('book_${_bookId}_page', _currentPage);
      await LastReadBookStore.instance.updatePage(
        bookId: _bookId!,
        page: _currentPage,
      );
      if (_currentCfi.isNotEmpty) {
        await prefs.setString('book_${_bookId}_cfi', _currentCfi);
      }
      // Same debounce as the local save, so the server sees the position the
      // user actually settled on rather than every intermediate relocation.
      ReadingProgressReporter.instance
          .report(bookId: _bookId!, fraction: _progress);
      log('💾 Progress saved: ${(_progress * 100).toStringAsFixed(1)}%');
    } catch (e) {
      log('❌ Save progress error: $e');
    } finally {
      _isProgressSaving = false;
      _notify();
    }
  }

  Future<void> saveAndClose() async {
    _saveTimer?.cancel();
    _flushStreakResidual();
    _loadTimeoutTimer?.cancel();
    // Hand the screen brightness back to the system on the way out.
    await _releaseBrightness();
    await _saveProgress();
    _reset();
  }

  void _reset() {
    // Clear the report throttle too: reopening this book should re-sync its
    // position on the first save rather than being de-duped against what a
    // previous session already sent.
    if (_bookId != null) ReadingProgressReporter.instance.forget(_bookId!);
    _currentPage = 0;
    _totalPages = 0;
    _lastLoggedPage = null;
    _progress = 0.0;
    _isLoading = true;
    _showControls = true;
    _selectedText = '';
    _selectedCfi = null;
    _selectionRect = null;
    _chapters = [];
    _notify();
  }
}
