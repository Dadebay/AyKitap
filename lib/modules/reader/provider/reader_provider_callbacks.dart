part of 'reader_provider.dart';

/// epub.js WebView bridge callbacks: rendition-ready setup, saved-location
/// restore, highlight restore, relocation/page tracking and text selection.
/// This is the hot path every navigation inside a book runs through, so it
/// stays separate from the one-time [ReaderProviderLifecycle.initialize] and
/// from appearance/theme concerns it merely triggers.
extension ReaderProviderCallbacks on ReaderProvider {
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  double get progress => _progress;
  String get currentCfi => _currentCfi;
  bool get isAtLastPage => _isAtLastPage;

  /// This fires on epub.js's `displayed` event, which is emitted on *every*
  /// navigation — each chapter tap included — not once per book. Everything
  /// below is per-rendition setup, so it's guarded to run only the first time.
  void onEpubLoaded() {
    _loadTimeoutTimer?.cancel();
    _isLoading = false;
    _notify();

    if (_renditionConfigured) return;
    _renditionConfigured = true;
    log('📖 EPUB loaded — configuring rendition');

    // Push the saved page-change style into the freshly-created rendition —
    // it only lives in the webview, so it has to be re-applied per book. No
    // setFlow: every mode (scroll/Prokrutka included) reads paginated now.
    epubController.setPageTransition(mode: _pageTransition.name);

    // The chosen body font is a WebView @font-face, so it also has to be
    // (re)injected each time a book's rendition is created. Once is enough:
    // epubView.js caches the face and its rendition.hooks.content hook
    // re-injects it into every section as that section renders.
    _applyReaderFont();

    // Font size and line spacing reach the rendition through
    // EpubDisplaySettings, which loadBook reads exactly once — and that read
    // races initialize()'s awaits on the bookmark store and SharedPreferences.
    // Whichever side wins, re-applying the loaded values here is what makes the
    // book actually open at the size the reader chose.
    epubController.setFontSize(fontSize: _fontSize);
    epubController.updateTheme(theme: _buildEpubTheme());

    // Restore reading position. A saved CFI is handed to EpubViewer as
    // initialCfi and the WebView already opened there directly — jumping
    // again here would just repeat that navigation. Only legacy saves from
    // before the CFI was persisted (progress-only) still need the old
    // jump-after-load fallback, which waits on book.locations.generate() and
    // was the source of the "book reopens at the wrong page" race on large
    // books. Must not run on later navigations: it would drag the reader back
    // out of the chapter they just tapped, and since the jump itself emits
    // `displayed`, it would re-arm itself indefinitely.
    if (_savedCfi.isEmpty && _progress > 0.0) {
      Future.delayed(const Duration(milliseconds: 600), () {
        epubController.toProgressPercentage(_progress);
      });
    }

    _restoreHighlights();
  }

  /// Redraws this book's saved highlights (TZ §12.7) — epub.js's
  /// `rendition.annotations` persist across navigation within one rendition,
  /// so this only needs to run once per book, same as the rest of this
  /// one-time setup. Without it, a highlight painted on the page vanished the
  /// moment the book was closed and reopened, even though the note itself
  /// was still saved in the profile's Notlar list.
  Future<void> _restoreHighlights() async {
    final bookId = _bookId;
    if (bookId == null) return;
    await NotesStore.instance.load();
    final highlights = NotesStore.instance.highlightsForBook(bookId: bookId);
    for (final note in highlights) {
      epubController.addHighlight(
        cfi: note.cfi!,
        color: Color(note.colorValue),
        opacity: HighlightColors.highlightOpacity,
      );
    }
  }

  /// Fired once after epub.js finishes a fresh `book.locations.generate()`
  /// scan (never on a book opened from a cached [ReaderProviderPersistence]'s
  /// cached JSON, since nothing new was generated then). Persisted so the
  /// next open of this book can skip that scan entirely via
  /// [EpubViewer.initialLocations].
  Future<void> onLocationsGenerated(String json) async {
    if (_bookId == null || json.isEmpty) return;
    _savedLocationsJson = json;
    log('📍 Locations generated (${json.length} chars) — caching for next open');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_${_bookId}_locations', json);
    } catch (e) {
      log('❌ Save locations error: $e');
    }
  }

  void onRelocated(EpubLocation location) {
    _progress = location.progress;
    _currentCfi = location.startCfi;
    _currentHref = location.href ?? '';
    // Older payloads (and books whose files hold no anchored TOC entries) carry
    // no tocHref; the file is then the whole answer.
    _currentTocHref = location.tocHref ?? _currentHref;
    _onPageChanged(location.page, location.totalPages);
    log('📍 file=$_currentHref toc=$_currentTocHref p=$_currentPage/$_totalPages → ${currentChapterTitle ?? '—'}');
    _notify();

    // Debounced save
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  /// Page state, folded in from each relocation. [current] and [total] are 0
  /// while sakura_epub is still counting the book (see [EpubLocation.page]) —
  /// the old numbers are kept in that window rather than flashing a 0 on screen.
  void _onPageChanged(int current, int total) {
    if (total <= 0 || current <= 0) return;
    _currentPage = current;
    _totalPages = total;
    _isAtLastPage = current >= total;
    // Only forward turns count as "pages read" — and the very first callback
    // after a load/position-restore is skipped so jumping back into a book
    // isn't logged as having read every page up to that point.
    if (_lastLoggedPage != null && current > _lastLoggedPage!) {
      StreakService.instance
          .recordPageRead(count: (current - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = current;
  }

  void onTextSelected(EpubTextSelection selection) {
    _selectedText = selection.selectedText;
    _selectedCfi = selection.selectionCfi;
    _notify();
  }

  void onSelection(
      String text, String? cfi, Rect? selectionRect, Rect? viewRect) {
    _selectedText = text;
    _selectedCfi = cfi;
    _selectionRect = selectionRect;
    _notify();
  }

  void onDeselection() {
    _selectedText = '';
    _selectedCfi = null;
    _selectionRect = null;
    _notify();
  }
}
