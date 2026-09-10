part of 'reader_provider.dart';

/// Book-open initialization, the app-lifecycle-driven streak ping, the
/// "did the book ever load" watchdog, and dispose-time cleanup. Split out
/// from the rest of [ReaderProvider] because every method here is about the
/// reader's own lifecycle rather than what's on screen once it's open.
extension ReaderProviderLifecycle on ReaderProvider {
  bool get isLoading => _isLoading;
  bool get isProgressSaving => _isProgressSaving;
  bool get loadFailed => _loadFailed;

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize({required int bookId, String bookTitle = ''}) async {
    _bookId = bookId;
    _bookTitle = bookTitle;
    _isLoading = true;
    _loadFailed = false;
    // A new book gets a new rendition, so its setup has to run again.
    _renditionConfigured = false;
    _notify();
    _startLoadTimeout();

    // Bookmarks live app-wide; make sure they're in memory before the top bar
    // asks whether this page is marked.
    await BookmarksStore.instance.load();

    final prefs = await SharedPreferences.getInstance();
    _progress = prefs.getDouble('book_${bookId}_progress') ?? 0.0;
    _currentPage = prefs.getInt('book_${bookId}_page') ?? 0;
    _savedCfi = prefs.getString('book_${bookId}_cfi') ?? '';
    _savedLocationsJson = prefs.getString('book_${bookId}_locations');
    _lastLoggedPage = null;
    // Guard the saved position until the book has actually opened at it —
    // see [_restoringPosition] and [_verifyRestoredPosition].
    _restoreTargetProgress = _progress;
    _restoringPosition = _savedCfi.isNotEmpty && _progress > 0.0;

    // No saved choice yet (first book ever opened): default the page to the
    // app's own light/dark setting instead of always opening white, so a dark-
    // mode app doesn't dump the reader into a blindingly bright page.
    final savedTheme = prefs.getInt('reader_theme');
    _themeMode = savedTheme != null
        ? ReaderThemeMode
            .values[savedTheme.clamp(0, ReaderThemeMode.values.length - 1)]
        : (AppTheme.instance.isDark
            ? ReaderThemeMode.dark
            : ReaderThemeMode.white);

    final savedFont = prefs.getInt('reader_font') ?? 0;
    _fontFamily = ReaderFontFamily
        .values[savedFont.clamp(0, ReaderFontFamily.values.length - 1)];

    _fontSize =
        prefs.getDouble('reader_font_size') ?? ReaderProvider.defaultFontSize;
    _lineSpacing = prefs.getDouble('reader_line_spacing') ?? 1.5;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    // Shared across every reader (like brightness), so the filter the reader
    // set in the PDF reader is still on when they open an EPUB.
    _eyeCare = prefs.getDouble('reader_eye_care') ?? 0.0;
    // Apply the saved reading brightness to the device screen now that we're
    // in the reader (restored to system brightness again on close).
    _applyReaderBrightness();

    // No saved choice yet: default to scroll (Prokrutka) — a continuous
    // vertical scroll needs a genuinely vertical swipe to move, so it never
    // hits the gesture/animation mismatch a horizontal-swiped paginated mode
    // can (see the 'slide' transition's own doc comment in epubView.js).
    final savedTransition = prefs.getInt('reader_page_transition') ??
        ReaderPageTransition.scroll.index;
    _pageTransition = ReaderPageTransition.values[
        savedTransition.clamp(0, ReaderPageTransition.values.length - 1)];
    _leftHandMode = prefs.getBool('reader_left_hand') ?? false;

    _notify();
    // Publish the restored page/progress (and cleared bookmark/chapter state)
    // before the book visually opens — see _updateProgressSnapshot.
    _updateProgressSnapshot();

    if (!_lifecycleObserverAdded) {
      _lifecycleObserverAdded = true;
      WidgetsBinding.instance.addObserver(this);
    }
    _startStreakPing();
  }

  void _startStreakPing() => _streakPing.start();

  /// Sends whatever active-reading time has elapsed since the last periodic
  /// tick (0 if the timer never fired yet) — called from `saveAndClose`/
  /// `dispose` (reader closed) and [_handleAppLifecycleState] (app
  /// backgrounded) so a reading burst shorter than the streak ping interval
  /// still counts instead of being silently dropped when the timer stops.
  /// See [ReaderStreakPing.flushResidual] for why it's safe to call twice.
  void _flushStreakResidual() => _streakPing.flushResidual();

  void _handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _flushStreakResidual();
        _flushPendingProgressSave();
      case AppLifecycleState.resumed:
        _startStreakPing();
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Writes the current position out *now* instead of waiting for
  /// [onRelocated]'s 2-second debounce to elapse.
  ///
  /// Backgrounding the app is the one moment that debounce can't survive: the
  /// pending timer is still counting when the process is suspended, and a
  /// suspended app can be killed outright without ever running it — so every
  /// page turned in the last two seconds of a session was silently lost, and
  /// reopening the book landed on whatever page the last timer that *did*
  /// fire had saved. Reading a book right up to the moment of swiping the app
  /// away is the normal way to leave a reader, which is why this looked like
  /// the position was never saved at all.
  void _flushPendingProgressSave() {
    _saveTimer?.cancel();
    // Nothing on screen yet is worth more than what's already on disk: the
    // book is still opening at the saved position, so writing the
    // half-restored one over it would be the very regression
    // [_restoringPosition] exists to prevent.
    if (_restoringPosition) return;
    unawaited(_saveProgress());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Epub load watchdog
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts (or restarts) the "did the book ever load" watchdog. epub.js
  /// gives no guarantee that either `displayed` or `displayError` fires for
  /// every failure mode (a hung WebView, a book.open() that never settles),
  /// so this is the last-resort fallback that gets the reader out of an
  /// infinite loading spinner.
  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(ReaderProvider._loadTimeout, () {
      if (_isLoading && !_loadFailed) {
        log('⏱️ EPUB load timeout — no displayed/error event within ${ReaderProvider._loadTimeout.inSeconds}s');
        onEpubLoadFailed();
      }
    });
  }

  /// Fires on epub.js's `displayError` (book.open() rejected, or a page
  /// failed to render), or on [_startLoadTimeout] giving up. Whichever came
  /// first wins — both funnel here idempotently.
  void onEpubLoadFailed() {
    if (_loadFailed) return;
    _loadTimeoutTimer?.cancel();
    _loadFailed = true;
    _isLoading = false;
    // Nothing ever opened, so there's no restore left to guard — and leaving
    // it armed would block this session's saves for good.
    _restoringPosition = false;
    log('❌ EPUB failed to load');
    _notify();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────────────────────────

  void _disposeCleanup() {
    _saveTimer?.cancel();
    _flushStreakResidual();
    if (_lifecycleObserverAdded) {
      _lifecycleObserverAdded = false;
      WidgetsBinding.instance.removeObserver(this);
    }
    _loadTimeoutTimer?.cancel();
    // Safety net: covers exit paths that don't route through saveAndClose.
    _releaseBrightness();
  }
}
