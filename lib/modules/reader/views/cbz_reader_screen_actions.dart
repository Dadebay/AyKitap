part of 'cbz_reader_screen.dart';

/// Appearance setters, progress persistence, page-turn/scrub handling,
/// bookmarks (TZ §12.1) and notes (TZ §12.7) — everything that changes this
/// screen's state without owning any of its widget tree.
extension _CbzReaderScreenActions on _CbzReaderScreenState {
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

  Future<void> _setGutter(bool dark) async {
    _setState(() => _darkGutter = dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_cbz_dark_gutter', dark);
  }

  Future<void> _setFit(BoxFit fit) async {
    _setState(() => _fit = fit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_cbz_fit_cover', fit == BoxFit.cover);
  }

  Future<void> _setViewMode(CbzViewMode mode) async {
    if (_viewMode == mode) return;
    _setState(() => _viewMode = mode);
    // The other mode's controller isn't attached yet on this frame, so land
    // the reader back on the page it was already reading once it is.
    final page = _currentPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goToPage(page);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_cbz_view_mode', mode.index);
  }

  void _toggleControls() => _setState(() => _showControls = !_showControls);

  // ── Progress persistence ─────────────────────────────────────────────────
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_${_bookId}_cbz_page', _currentPage);
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

  // ── Page changes ─────────────────────────────────────────────────────────
  void _onPageChanged(int page) {
    if (_lastLoggedPage != null && page > _lastLoggedPage!) {
      StreakService.instance
          .recordPageRead(count: (page - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = page;
    _setState(() => _currentPage = page);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void _jumpToProgress(double value) {
    if (_totalPages <= 0) return;
    _goToPage((value * (_totalPages - 1)).round());
  }

  /// The one way to move to a page, whichever mode is showing — the scrubber,
  /// a bookmark and "go to page" all land here. In paged mode that's a
  /// PageView index; in scroll mode it's a scroll offset, which only
  /// [CbzScrollMetrics] can work out (page boundaries no longer line up with
  /// screen boundaries there).
  void _goToPage(int page) {
    if (_totalPages <= 0) return;
    final target = page.clamp(0, _totalPages - 1);
    if (_viewMode == CbzViewMode.paged) {
      if (_pageController.hasClients) _pageController.jumpToPage(target);
      return;
    }
    final metrics = _metrics;
    if (metrics == null || !_scrollController.hasClients) {
      // Metrics/attachment aren't ready on the very first frame after
      // extraction — retry once the list has been laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewMode != CbzViewMode.scroll) return;
        final m = _metrics;
        if (m == null || !_scrollController.hasClients) return;
        _scrollController.jumpTo(
          m
              .offsetOf(target)
              .clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      });
      _onPageChanged(target);
      return;
    }
    _scrollController.jumpTo(
      metrics
          .offsetOf(target)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  // ── Bookmarks (TZ §12.1) ─────────────────────────────────────────────────
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

  // ── Notes (TZ §12.7) ─────────────────────────────────────────────────────
  /// Anchored to the current page: a comic page is a bitmap, so there is no
  /// passage to quote — see [showAddPageNoteSheet].
  Future<void> _addNote() => showAddPageNoteSheet(
        context,
        bookId: _bookId,
        realBookId: widget.realBookId,
        bookTitle: widget.title,
        page: _currentPage + 1,
        totalPages: _totalPages,
      );
}
