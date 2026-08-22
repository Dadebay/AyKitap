part of 'cbz_reader_screen.dart';

/// Screen open/close plumbing: the app-lifecycle-driven streak ping,
/// restoring saved settings, and unpacking the zip on open.
extension _CbzReaderScreenLifecycle on _CbzReaderScreenState {
  void _handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _streakPing.flushResidual();
      case AppLifecycleState.resumed:
        _streakPing.start();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _bootstrap() async {
    await BookmarksStore.instance.load();
    final prefs = await SharedPreferences.getInstance();
    _initialPage = prefs.getInt('book_${_bookId}_cbz_page') ?? 0;
    _currentPage = _initialPage;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _eyeCare = prefs.getDouble('reader_eye_care') ?? 0.0;
    // No saved choice yet: default the gutter to the app's own light/dark
    // setting rather than always opening dark.
    _darkGutter =
        prefs.getBool('reader_cbz_dark_gutter') ?? AppTheme.instance.isDark;
    _fit = (prefs.getBool('reader_cbz_fit_cover') ?? false)
        ? BoxFit.cover
        : BoxFit.contain;
    // Continuous scroll is the default — a comic page is taller than the
    // screen, so fitting it whole is what makes it unreadable. See
    // [CbzViewMode].
    _viewMode = CbzViewMode.values[
        (prefs.getInt('reader_cbz_view_mode') ?? CbzViewMode.scroll.index)
            .clamp(0, CbzViewMode.values.length - 1)];
    await _brightnessController.apply(_brightness);
    await _extract();
  }

  /// Clamps the restored page against the page count extraction just
  /// resolved (a stale save or a re-extracted book can put it out of range —
  /// fix for #12) and lands the already-constructed [_pageController] there.
  /// The controller's own `initialPage` was fixed at 0 back when it was
  /// created in initState — before the real page was known — so getting to
  /// the right page now takes an explicit jump once the PageView carrying it
  /// has actually mounted.
  void _applyRestoredPage() {
    if (_totalPages == 0) return;
    _initialPage = _initialPage.clamp(0, _totalPages - 1);
    _currentPage = _initialPage;
    if (_initialPage == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _goToPage(_initialPage);
    });
  }

  /// Unpacks the zip to one image file per page, in a folder keyed by this
  /// file's own path — a second open of the same book reuses it instead of
  /// re-extracting. A `.done` marker is what "reuse" checks for, so a run that
  /// got killed mid-extraction is redone rather than served half-finished.
  /// The actual decode/write work happens off the UI isolate — see
  /// [extractCbzOnIsolate] for why.
  Future<void> _extract() async {
    try {
      final cacheDir = await cbzPageCacheDirFor(widget.filePath);
      // Captured as plain Strings, not `cacheDir`/`widget` themselves — see
      // extractCbzOnIsolate's doc on what Isolate.run's closure may capture.
      final zipPath = widget.filePath;
      final cacheDirPath = cacheDir.path;
      final (pages, noImages) = await runCbzExtraction((zipPath, cacheDirPath));

      if (!mounted) return;
      if (noImages) {
        _setState(() {
          _error = ReaderStrings.cbzNoImagesError;
          _isLoading = false;
        });
        return;
      }
      // Needed before the scroll list can be built: every page's height comes
      // from its own ratio. Cached on disk after the first open.
      final ratios = await cbzPageAspectRatios(
          filePath: widget.filePath, pagePaths: pages);
      if (!mounted) return;
      _setState(() {
        _pagePaths = pages;
        _aspectRatios = ratios;
        _isLoading = false;
        _applyRestoredPage();
      });
    } catch (e) {
      if (mounted) {
        _setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}
