import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/reading_progress_reporter.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stable_hash.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../utils/eye_care.dart';
import '../utils/page_note.dart';
import '../utils/pdf_book_opener.dart';
import '../utils/reader_orientation.dart';
import '../widgets/pdf_bookmarks_sheet.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_go_to_page_sheet.dart';
import '../widgets/pdf_settings_sheet.dart';
import '../widgets/reader_top_bar.dart';

/// Full-screen PDF reader, styled to match the EPUB [ReaderScreen] as closely
/// as a fixed-layout format allows.
///
/// PDFs are page images, not reflowable text, so the reader features that act
/// on text simply have nothing to act on and aren't offered here: font
/// size/family/line spacing (the page is a fixed picture), in-book search and
/// the chapter list (these files carry no text layer or outline), and
/// *highlights* (there is no selection to paint). What *does* carry over is
/// wired up: the reader's top bar, focus mode (tap to hide the chrome), a page
/// scrubber, device brightness (TZ §12.4), per-page bookmarks (TZ §12.1),
/// notes anchored to the page rather than to a passage
/// ([showAddPageNoteSheet]), and progress that's saved and restored across
/// sessions.
///
/// Pages are drawn by [PdfViewer] (pdfrx). This used to be flutter_pdfview's
/// native PDFium view, and the two could not coexist: pdfrx ships
/// `libpdfium.so` and flutter_pdfview ships `libmodpdfium.so`, *both*
/// declaring `SONAME libpdfium.so`, which is also what flutter_pdfview's
/// `libjniPdfium.so` links against. Whichever loaded first won that name for
/// the whole process — and since [PdfReflowService] classifies a PDF (loading
/// pdfrx's copy) before this screen opens, flutter_pdfview's renderer ended up
/// calling into *pdfrx's* PDFium, which has Dart FFI font callbacks installed.
/// A page needing a substituted font then invoked Dart from flutter_pdfview's
/// native render thread — "Cannot invoke native callback outside an isolate" —
/// and aborted the process. Books whose fonts are all embedded never hit the
/// font mapper and so never crashed, which is why it looked file-specific.
/// One engine removes the conflict at its root.
///
/// A [Listener] over the viewer recognises a tap without swallowing scroll (a
/// GestureDetector would consume the drag the viewer needs), the same way
/// the EPUB reader reads taps back out of its WebView.
class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  /// Stable id used to scope this book's saved page and bookmarks. Callers that
  /// already have one (the catalogue / debug list) pass it so progress lines up
  /// with the rest of the app; otherwise the file path stands in.
  final int? bookId;

  /// The real `/books/:id` catalogue id — see [ReaderScreen.realBookId]. Set
  /// only for a downloaded catalogue book; notes taken here are then also
  /// persisted via `POST /users/notes`, which is what puts them in the
  /// profile's "Notlar" list. Null for the user's own imported PDFs, whose
  /// notes stay local, exactly as an imported EPUB's do.
  ///
  /// Deliberately separate from [bookId]: that one falls back to a hashed file
  /// path for an import, and a hash is not an id the backend would accept.
  final int? realBookId;

  /// This book's pages are images (a scan, a manga/comic) rather than text —
  /// see [PdfReflowService.isImageOnlyPdf], which [PdfOpeningScreen] resolves
  /// before handing over. Such a book opens filling the screen's *width* and
  /// scrolling down the page, since fitting a tall picture page to the screen's
  /// height shrinks it to an unreadable sliver. Only the opening default is
  /// affected — the settings sheet still switches modes freely afterwards.
  final bool imageOnly;

  const PdfReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.bookId,
    this.realBookId,
    this.imageOnly = false,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> with WidgetsBindingObserver {
  final _controller = PdfViewerController();

  /// 0-based throughout this screen — pdfrx speaks 1-based page numbers, so
  /// the two are converted at the boundary rather than churning every
  /// bookmark/note/progress key that already stores a 0-based index.
  int _currentPage = 0;
  int _totalPages = 0;
  int _initialPage = 0;
  int? _lastLoggedPage;
  bool _isLoading = true;
  String? _error;

  bool _showControls = true;
  double _brightness = 1.0;
  // Blue-light "eye care" wash, shared across every reader via the
  // `reader_eye_care` pref (see ReaderProvider). 0.0 = off.
  double _eyeCare = 0.0;
  PdfColorMode _colorMode = PdfColorMode.light;
  PdfFitMode _fitPolicy = PdfFitMode.page;
  PdfViewMode _viewMode = PdfViewMode.paged;

  // Tap vs. scroll discrimination for the focus-mode toggle.
  Offset? _touchStart;
  DateTime? _touchStartAt;

  Timer? _saveTimer;
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 60);
  final Stopwatch _streakStopwatch = Stopwatch();

  int get _bookId => widget.bookId ?? stableBookKey(widget.filePath);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    enableReaderLandscape();
    _restoreState();
    WidgetsBinding.instance.addObserver(this);
    _startStreakPing();
  }

  void _startStreakPing() {
    _streakPingTimer?.cancel();
    _streakStopwatch
      ..reset()
      ..start();
    _streakPingTimer = Timer.periodic(_streakPingInterval, (_) {
      StreakService.instance.recordActiveSeconds(_streakPingInterval.inSeconds);
      _streakStopwatch.reset();
    });
  }

  /// See [ReaderProvider]'s doc comment on the equivalent method — sends
  /// whatever active-reading time has elapsed since the last periodic tick
  /// instead of letting it vanish when the timer is cancelled.
  void _flushStreakResidual() {
    _streakPingTimer?.cancel();
    final residual = _streakStopwatch.elapsed.inSeconds;
    _streakStopwatch
      ..stop()
      ..reset();
    if (residual > 0) StreakService.instance.flushResidual(seconds: residual);
  }

  /// See [ReaderProvider]'s doc comment on the equivalent override — only
  /// `paused` (genuinely backgrounded) and `resumed` toggle the ping;
  /// `inactive`'s brief, non-backgrounding interruptions are left alone.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _flushStreakResidual();
      case AppLifecycleState.resumed:
        _startStreakPing();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _restoreState() async {
    await BookmarksStore.instance.load();
    final prefs = await SharedPreferences.getInstance();
    _initialPage = prefs.getInt('book_${_bookId}_pdf_page') ?? 0;
    _currentPage = _initialPage;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _eyeCare = prefs.getDouble('reader_eye_care') ?? 0.0;
    // New three-way mode; fall back to the old dark-gutter bool for anyone
    // upgrading (their dark gutter maps to night, otherwise light). With
    // neither ever saved (first PDF ever opened, or a fresh install), default
    // to night rather than the app theme — night is the app-wide reading
    // default regardless of the shell's own light/dark setting.
    final savedMode = prefs.getInt('reader_pdf_color_mode');
    final legacyDarkGutter = prefs.getBool('reader_pdf_dark_gutter');
    if (savedMode != null) {
      _colorMode = PdfColorMode.values[savedMode.clamp(0, PdfColorMode.values.length - 1)];
    } else if (legacyDarkGutter != null) {
      _colorMode = legacyDarkGutter ? PdfColorMode.night : PdfColorMode.light;
    } else {
      _colorMode = PdfColorMode.night;
    }
    // Continuous scroll is the default — see [PdfViewMode]. Paged (sideways,
    // one page per swipe) is opt-in for anyone who prefers reading it like a
    // normal book.
    //
    // The mode preference is app-wide, which is right for text PDFs but wrong
    // for an image book: a reader who once chose paged for a novel would then
    // have every manga open with its tall pages squeezed whole onto the screen
    // — the exact unreadable sliver [PdfViewMode.scroll] exists to avoid. So an
    // image book ignores the app-wide preference and opens in scroll unless a
    // choice was made *for this book*, which [_setViewMode] records separately.
    final bookMode = prefs.getInt('book_${_bookId}_pdf_view_mode');
    final defaultMode =
        widget.imageOnly ? PdfViewMode.scroll.index : (prefs.getInt('reader_pdf_view_mode') ?? PdfViewMode.scroll.index);
    _viewMode = PdfViewMode.values[(bookMode ?? defaultMode).clamp(0, PdfViewMode.values.length - 1)];
    // Fit-width is the default, matching the default scroll mode — see
    // [_setViewMode] for why the two travel together. Whole-page is what paged
    // mode needs (there's no way to scroll to the rest of a page fit-width
    // left below the fold), so it only kicks in once the user picks paged.
    final bookFitWidth = prefs.getBool('book_${_bookId}_pdf_fit_width');
    final defaultFitWidth =
        widget.imageOnly ? true : (prefs.getBool('reader_pdf_fit_width') ?? (_viewMode == PdfViewMode.scroll));
    _fitPolicy = (bookFitWidth ?? defaultFitWidth) ? PdfFitMode.width : PdfFitMode.page;
    _applyBrightness();
    if (mounted) setState(() {});
  }

  /// Records the preference and hands straight back to [PdfOpeningScreen],
  /// which owns the conversion.
  ///
  /// It deliberately does *not* convert here and push the text reader
  /// itself: the conversion drives PDFium over the whole document, and
  /// starting that while this screen's own [PdfViewer] still holds the same
  /// file open put two readers on one document. Replacing this route first
  /// means the viewer is torn down before any of that begins.
  Future<void> _switchToTextView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(preferFixedPrefKey(_bookId), false);
    await _saveProgress();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PdfOpeningScreen(
          filePath: widget.filePath,
          title: widget.title,
          bookId: _bookId,
          realBookId: widget.realBookId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _flushStreakResidual();
    _releaseBrightness();
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    restoreAppPortraitLock();
    super.dispose();
  }

  // ── Brightness (TZ §12.4), device-level, same policy as ReaderProvider ─────
  Future<void> _applyBrightness() async {
    try {
      // Always set an explicit value, even at 1.0 — see ReaderProvider's
      // _applyReaderBrightness for why releasing control at max used to make
      // 100% visibly dimmer than the slider promised.
      await ScreenBrightness().setApplicationScreenBrightness(_brightness.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> _releaseBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (_) {}
  }

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
        ReadingProgressReporter.instance.report(bookId: catalogueId, fraction: fraction);
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
    setState(() => _showControls = !_showControls);
  }

  // ── Page changes ───────────────────────────────────────────────────────────
  /// [pageNumber] is pdfrx's 1-based page; everything below it is 0-based.
  void _onPageChanged(int? pageNumber) {
    if (pageNumber == null) return;
    final p = pageNumber - 1;
    log('📄 PDF page=$pageNumber/$_totalPages');
    if (_lastLoggedPage != null && p > _lastLoggedPage!) {
      StreakService.instance.recordPageRead(count: (p - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = p;
    setState(() => _currentPage = p);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void _jumpToProgress(double value) {
    if (_totalPages <= 0) return;
    final target = (value * (_totalPages - 1)).round().clamp(0, _totalPages - 1);
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
  bool get _isCurrentPageBookmarked => BookmarksStore.instance.isBookmarked(_bookId, _pageKey);

  Future<void> _toggleBookmark() async {
    final added = await BookmarksStore.instance.toggle(
      bookId: _bookId,
      bookTitle: widget.title,
      cfi: _pageKey,
      chapterTitle: ReaderStrings.pageOfPages(_currentPage + 1, _totalPages),
      progress: _totalPages > 0 ? (_currentPage + 1) / _totalPages : 0.0,
    );
    if (!mounted) return;
    setState(() {});
    context.showAppSnackBar(added ? ReaderStrings.bookmarkAdded : ReaderStrings.bookmarkRemoved);
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

  Future<void> _setBrightness(double v) async {
    setState(() => _brightness = v.clamp(0.1, 1.0));
    await _applyBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  Future<void> _setEyeCare(double v) async {
    setState(() => _eyeCare = v.clamp(0.0, 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_eye_care', _eyeCare);
  }

  Future<void> _setColorMode(PdfColorMode mode) async {
    if (_colorMode == mode) return;
    // Both night and sepia are pure Flutter overlays now (see
    // [_NightModeFilter]), so neither reloads the document — but pinning the
    // page costs nothing and keeps this in step with [_setFit]/[_setViewMode],
    // which do rebuild the viewer.
    setState(() {
      _initialPage = _currentPage;
      _colorMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_pdf_color_mode', mode.index);
  }

  Future<void> _setFit(PdfFitMode fit) async {
    if (_fitPolicy == fit) return;
    setState(() {
      _initialPage = _currentPage;
      _fitPolicy = fit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_pdf_fit_width', fit == PdfFitMode.width);
    // Also recorded against this book, so the choice outranks the image-book
    // default next time it's opened (see [_restoreState]).
    await prefs.setBool('book_${_bookId}_pdf_fit_width', fit == PdfFitMode.width);
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
    setState(() {
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
    await prefs.setBool('book_${_bookId}_pdf_fit_width', fit == PdfFitMode.width);
  }

  // ── Sheets ─────────────────────────────────────────────────────────────────
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
            if (mounted) setState(() {});
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
      builder: (_) => PdfGoToPageSheet(currentPage: _currentPage + 1, totalPages: _totalPages),
    );
    // The sheet speaks in 1-based page numbers, this screen in 0-based indices.
    if (page != null) _goToPage(page - 1);
  }

  // ── Page layout ────────────────────────────────────────────────────────────
  /// Lays the document out for the current [_viewMode].
  ///
  /// * [PdfViewMode.paged] — pages side by side, each centred in a slot as
  ///   wide as the widest page, with a gutter between them. Each page keeps
  ///   its own size, so a book carrying oversized inserts (promo pages
  ///   appended at a different page size) doesn't shrink its normal pages to
  ///   match them.
  /// * [PdfViewMode.scroll] — pages stacked vertically with **no** gap, so
  ///   they run together as one continuous strip. That seamlessness is the
  ///   whole point for a webtoon/manhwa PDF, where a visible gap every screen
  ///   reads as a border printed on the picture.
  PdfPageLayout _layoutPages(List<PdfPage> pages, PdfViewerParams params) {
    final paged = _viewMode == PdfViewMode.paged;
    final gap = paged ? params.margin : 0.0;
    final layouts = <Rect>[];

    if (paged) {
      final slot = pages.fold(0.0, (w, p) => math.max(w, p.width));
      final tallest = pages.fold(0.0, (h, p) => math.max(h, p.height));
      var x = gap;
      for (final page in pages) {
        layouts.add(Rect.fromLTWH(
          x + (slot - page.width) / 2,
          gap + (tallest - page.height) / 2,
          page.width,
          page.height,
        ));
        x += slot + gap;
      }
      return PdfPageLayout(pageLayouts: layouts, documentSize: Size(x, tallest + gap * 2));
    }

    final width = pages.fold(0.0, (w, p) => math.max(w, p.width));
    var y = 0.0;
    for (final page in pages) {
      layouts.add(Rect.fromLTWH((width - page.width) / 2, y, page.width, page.height));
      y += page.height;
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(width, y));
  }

  @override
  Widget build(BuildContext context) {
    // Gutter behind the page, and whether this mode reads as a dark surface
    // (drives the tint of the focus page-number, loading and error text).
    final bg = switch (_colorMode) {
      PdfColorMode.light => Colors.white,
      PdfColorMode.sepia => const Color(0xFFEADFC6),
      PdfColorMode.night => const Color(0xFF1C1C1E),
    };
    final isDarkSurface = _colorMode == PdfColorMode.night;
    final nightMode = _colorMode == PdfColorMode.night;
    final inFocus = !_showControls && !_isLoading && _error == null;
    final focusColor = isDarkSurface ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── The page ───────────────────────────────────────────────────
          if (_error == null)
            Positioned.fill(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                child: _NightModeFilter(
                  // Inverts the rendered page to light-on-dark — the "göz
                  // goraýyş" dark reading the user asked for. Ideal for text
                  // PDFs (black-on-white becomes white-on-black) and poor for
                  // scanned/manga pages (they become photo negatives), which
                  // is why it's an opt-in mode rather than the default. Done
                  // as a Flutter layer, so unlike PDFium's Android-only night
                  // mode it now works identically on iOS.
                  enabled: nightMode,
                  child: PdfViewer.file(
                    widget.filePath,
                    controller: _controller,
                    // The layout and the initial zoom are read when the viewer
                    // lays out, so changing either has to rebuild it — that's
                    // what varying the key does. `initialPageNumber` carries
                    // our place across that rebuild and across reopening the
                    // book. (Sepia and night aren't in the key: both are
                    // Flutter overlays, not render changes, so switching to or
                    // from them mustn't reload the file.)
                    key: ValueKey('pdf_${_fitPolicy.name}_${_viewMode.name}_$_initialPage'),
                    initialPageNumber: _initialPage + 1,
                    params: PdfViewerParams(
                      backgroundColor: bg,
                      // Paged mode lays pages left-to-right, one per sideways
                      // swipe, like a real page turn; scroll mode stacks them
                      // top-to-bottom with no gap so a tall webtoon page runs
                      // straight into the next. See [_layoutPages].
                      layoutPages: _layoutPages,
                      // Paged mode moves one page at a time along its own
                      // axis; locking the pan to that axis is what keeps a
                      // sideways swipe from drifting the page diagonally.
                      panAxis: _viewMode == PdfViewMode.paged ? PanAxis.horizontal : PanAxis.free,
                      // Fit-width means "fill the screen's width and scroll
                      // down the rest", which is pdfrx's *alternative* fit
                      // scale (its default fits the whole page). Falling back
                      // to the default keeps a page on screen if the
                      // alternative isn't available yet.
                      sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
                        calculateInitialZoom: (document, controller, alternativeFitZoom, coverZoom) =>
                            _fitPolicy == PdfFitMode.width ? alternativeFitZoom : coverZoom,
                      ),
                      onViewerReady: (document, controller) => setState(() {
                        _totalPages = document.pages.length;
                        _isLoading = false;
                      }),
                      onPageChanged: _onPageChanged,
                      // The raw exception is developer noise, not something a
                      // reader should have to parse — log it and show a
                      // plain-language message instead. Returning an empty box
                      // lets this screen's own error state own the display.
                      errorBannerBuilder: (context, error, stackTrace, documentRef) {
                        log('❌ PDF open error: $error');
                        // The builder runs during layout, so the state change
                        // has to wait for the frame to finish.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted || _error != null) return;
                          setState(() {
                            _error = ReaderStrings.pdfOpenError;
                            _isLoading = false;
                          });
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),

          // ── Sepia eye-care wash ────────────────────────────────────────
          // A translucent warm tint laid over the whole page. Unlike night
          // mode this needs no native support — it's an ordinary Flutter layer
          // painted on top of the platform view, so it warms the page the same
          // way on Android and iOS. IgnorePointer keeps swipes/taps flowing
          // through to the PDF underneath.
          if (_colorMode == PdfColorMode.sepia && _error == null)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Color(0x24C8862A)),
              ),
            ),

          // ── Eye-care (blue-light) wash ─────────────────────────────────
          // A warm amber layer over the page, independent of the colour mode
          // so it stacks on top of light / sepia / night alike. Shared with
          // the EPUB reader via the same pref (see _eyeCare).
          if (readerEyeCareColor(_eyeCare, isDarkPage: isDarkSurface) != null && _error == null)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: readerEyeCareColor(_eyeCare, isDarkPage: isDarkSurface)!),
              ),
            ),

          // Same opening animation the EPUB reader uses, so a book looks like
          // it's opening rather than the app looking like it's stalled.
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: bg,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: Lottie.asset(
                          'assets/animations/book_reading_boy.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Text(
                        ReaderStrings.bookOpening,
                        style: TextStyle(
                          color: isDarkSurface ? Colors.white70 : Colors.black54,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_error != null)
            Positioned.fill(
              child: ColoredBox(
                color: bg,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedFileNotFound,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ReaderStrings.pdfOpenError,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkSurface ? Colors.white70 : Colors.black54,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                    progress: _totalPages > 0 ? (_currentPage + 1) / _totalPages : 0.0,
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

          // ── Focus-mode page number (bottom) ────────────────────────────
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
                      _totalPages > 0 ? '${_currentPage + 1} / $_totalPages' : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: focusColor, fontSize: 13, fontWeight: FontWeight.w500),
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

/// Colour-inverts its child when [enabled] — the PDF reader's night mode.
///
/// The matrix negates each channel (`-1 × c + 255`) and leaves alpha alone,
/// turning a black-on-white page into a white-on-black one. Applied over the
/// rendered pages rather than asked of the PDF engine, so it behaves the same
/// on both platforms; the surrounding gutter is already dark in this mode, so
/// only the pages themselves visibly change.
class _NightModeFilter extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _NightModeFilter({required this.enabled, required this.child});

  static const _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) =>
      enabled ? ColorFiltered(colorFilter: _invert, child: child) : child;
}
