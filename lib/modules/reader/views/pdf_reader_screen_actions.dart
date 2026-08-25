part of 'pdf_reader_screen.dart';

/// Progress persistence, page-turn/scrub handling, focus-mode tap
/// detection, bookmarks (TZ §12.1), notes (TZ §12.7) and the appearance
/// setters the settings sheet drives — everything that changes this
/// screen's state without owning any of its widget tree.
extension _PdfReaderScreenActions on _PdfReaderScreenState {
  // ── Progress persistence ───────────────────────────────────────────────────
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_${_bookId}_pdf_page', _currentPage);
    await LastReadBookStore.instance.updatePage(
      bookId: _bookId,
      page: _currentPage,
    );
    if (_totalPages > 0) {
      final fraction = (_currentPage + 1) / _totalPages;
      await prefs.setDouble('book_${_bookId}_progress', fraction);
      // `widget.bookId`, not `_bookId`: the latter falls back to a hashed
      // file path for a user's own imported book, which has no catalogue row
      // to report against.
      final catalogueId = widget.bookId;
      if (catalogueId != null) {
        ReadingProgressReporter.instance
            .report(bookId: catalogueId, fraction: fraction);
      }
    }
  }

  // ── Focus mode ─────────────────────────────────────────────────────────────
  void _onPointerDown(PointerDownEvent e) {
    _touchStart = e.position;
    _touchStartAt = DateTime.now();
  }

  void _onPointerUp(PointerUpEvent e) {
    final start = _touchStart;
    final at = _touchStartAt;
    _touchStart = null;
    _touchStartAt = null;
    if (start == null || at == null) return;
    // A real tap: little movement, short hold. Anything else is a scroll or a
    // pinch and must pass through to the PDF untouched.
    final moved = (e.position - start).distance;
    final held = DateTime.now().difference(at);
    if (moved > 16 || held > const Duration(milliseconds: 300)) return;
    _setState(() => _showControls = !_showControls);
  }

  // ── Page changes ───────────────────────────────────────────────────────────
  /// [pageNumber] is pdfrx's 1-based page; everything below it is 0-based.
  void _onPageChanged(int? pageNumber) {
    if (pageNumber == null) return;
    final p = pageNumber - 1;
    log('📄 PDF page=$pageNumber/$_totalPages');
    if (_lastLoggedPage != null && p > _lastLoggedPage!) {
      StreakService.instance
          .recordPageRead(count: (p - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = p;
    _setState(() => _currentPage = p);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void _jumpToProgress(double value) {
    if (_totalPages <= 0) return;
    final target =
        (value * (_totalPages - 1)).round().clamp(0, _totalPages - 1);
    _goToPage(target);
  }

  /// [page] is 0-based; pdfrx wants 1-based. Guarded on [PdfViewerController]
  /// being attached to a laid-out document — calling it before the viewer is
  /// ready throws rather than no-oping.
  void _goToPage(int page) {
    if (!_controller.isReady) return;
    unawaited(_controller.goToPage(pageNumber: page + 1));
  }

  // ── Bookmarks (TZ §12.1) ───────────────────────────────────────────────────
  // The store keys a position by an opaque string (a CFI for EPUBs); a PDF has
  // no CFI, so the page index stands in as `page:N`. That's enough for the
  // profile's cross-book list and to tell whether this page is already marked.
  String get _pageKey => 'page:$_currentPage';
  bool get _isCurrentPageBookmarked =>
      BookmarksStore.instance.isBookmarked(_bookId, _pageKey);

  Future<void> _toggleBookmark() async {
    final added = await BookmarksStore.instance.toggle(
      bookId: _bookId,
      bookTitle: widget.title,
      cfi: _pageKey,
      chapterTitle:
          ReaderBookmarkStrings.pageOfPages(_currentPage + 1, _totalPages),
      progress: _totalPages > 0 ? (_currentPage + 1) / _totalPages : 0.0,
    );
    if (!mounted) return;
    _setState(() {});
    context.showAppSnackBar(added
        ? ReaderBookmarkStrings.bookmarkAdded
        : ReaderBookmarkStrings.bookmarkRemoved);
  }

  // ── Notes (TZ §12.7) ───────────────────────────────────────────────────────
  /// Anchored to the current page, since a PDFium-drawn page offers no text
  /// selection to quote — see [showAddPageNoteSheet].
  Future<void> _addNote() => showAddPageNoteSheet(
        context,
        bookId: _bookId,
        realBookId: widget.realBookId,
        bookTitle: widget.title,
        page: _currentPage + 1,
        totalPages: _totalPages,
      );

  // ── Appearance settings ───────────────────────────────────────────────────
  Future<void> _setBrightness(double v) async {
    _setState(() => _brightness = v.clamp(0.1, 1.0));
    await _brightnessController.apply(_brightness);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  Future<void> _setEyeCare(double v) async {
    _setState(() => _eyeCare = v.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_eye_care', _eyeCare);
  }

  Future<void> _setColorMode(PdfColorMode mode) async {
    if (_colorMode == mode) return;
    // Both night and sepia are pure Flutter overlays now (see
    // [PdfNightModeFilter]), so neither reloads the document — but pinning
    // the page costs nothing and keeps this in step with [_setFit]/
    // [_setViewMode], which do rebuild the viewer.
    _setState(() {
      _initialPage = _currentPage;
      _colorMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_pdf_color_mode', mode.index);
  }

  /// Unlike [_setFit] and [_setViewMode] this doesn't pin [_initialPage] or
  /// rebuild the viewer: the crop is a Flutter layer around it
  /// ([PdfMarginCropBox]), so the document is never reloaded and the reader
  /// watches the margins close as they drag the slider.
  Future<void> _setMarginCrop(double v) async {
    _setState(() => _marginCrop = v.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_pdf_margin_crop', _marginCrop);
    // Also against this book: margins differ from book to book, so the one
    // the reader tuned here should be what it reopens with (see
    // [_restoreState]), the same way [_setFit] records its per-book copy.
    await prefs.setDouble('book_${_bookId}_pdf_margin_crop', _marginCrop);
  }

  Future<void> _setFit(PdfFitMode fit) async {
    if (_fitPolicy == fit) return;
    _setState(() {
      _initialPage = _currentPage;
      _fitPolicy = fit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_pdf_fit_width', fit == PdfFitMode.width);
    // Also recorded against this book, so the choice outranks the image-book
    // default next time it's opened (see [_restoreState]).
    await prefs.setBool(
        'book_${_bookId}_pdf_fit_width', fit == PdfFitMode.width);
  }

  Future<void> _setViewMode(PdfViewMode mode) async {
    if (_viewMode == mode) return;
    // Each mode only really works with one of the two fits (see
    // [PdfViewMode]), so switching brings the fit along rather than leaving
    // the reader in the broken pairing — scroll + whole-page would still
    // shrink a tall page to nothing, and paged + fit-width would still cut
    // one off below the fold. It's still a plain setting afterwards: the fit
    // tiles stay live, so anyone who wants the other pairing can pick it.
    final fit = mode == PdfViewMode.scroll ? PdfFitMode.width : PdfFitMode.page;
    _setState(() {
      _initialPage = _currentPage;
      _viewMode = mode;
      _fitPolicy = fit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_pdf_view_mode', mode.index);
    await prefs.setBool('reader_pdf_fit_width', fit == PdfFitMode.width);
    // See [_setFit]: the per-book copy is what lets an image book keep a mode
    // the reader picked for it, instead of reverting to the scroll default.
    await prefs.setInt('book_${_bookId}_pdf_view_mode', mode.index);
    await prefs.setBool(
        'book_${_bookId}_pdf_fit_width', fit == PdfFitMode.width);
  }
}
