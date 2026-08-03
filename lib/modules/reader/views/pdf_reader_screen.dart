import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/pdf_reflow_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/stable_hash.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../provider/reader_provider.dart';
import '../utils/eye_care.dart';
import '../utils/pdf_book_opener.dart';
import '../widgets/pdf_bookmarks_sheet.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_go_to_page_sheet.dart';
import '../widgets/pdf_settings_sheet.dart';
import '../widgets/reader_top_bar.dart';
import 'reader_view.dart';

/// Full-screen PDF reader, styled to match the EPUB [ReaderScreen] as closely
/// as a fixed-layout format allows.
///
/// PDFs are page images, not reflowable text, so the reader features that act
/// on text simply have nothing to act on and aren't offered here: font
/// size/family/line spacing (the page is a fixed picture), in-book search and
/// the chapter list (these files carry no text layer or outline), and
/// highlights/notes (nothing selectable). What *does* carry over is wired up:
/// the reader's top bar, focus mode (tap to hide the chrome), a page scrubber,
/// device brightness (TZ §12.4), per-page bookmarks (TZ §12.1), and
/// progress that's saved and restored across sessions.
///
/// The page itself is drawn by the native PDFium view ([PDFView]) rather than
/// re-rendered in Dart — much faster on the large scanned files this opens.
/// A [Listener] over it recognises a tap without swallowing scroll (a
/// GestureDetector would consume the drag the native view needs), the same way
/// the EPUB reader reads taps back out of its WebView.
class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  /// Stable id used to scope this book's saved page and bookmarks. Callers that
  /// already have one (the catalogue / debug list) pass it so progress lines up
  /// with the rest of the app; otherwise the file path stands in.
  final int? bookId;

  const PdfReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.bookId,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  PDFViewController? _controller;

  int _currentPage = 0; // 0-based, as PDFView reports it.
  int _totalPages = 0;
  int _initialPage = 0;
  int? _lastLoggedPage;
  bool _isLoading = true;
  String? _error;

  bool _showControls = true;
  // A non-null value means this book has a cached reflow (text) conversion
  // sitting unused because the reader forced fixed page images — see the
  // "view original PDF pages" option in ReaderSettingsSheet. Offering the
  // reverse switch here only when this exists means the option shows up
  // exactly for a book the reader themselves stepped out of reflow mode.
  String? _reflowEpubPath;
  double _brightness = 1.0;
  // Blue-light "eye care" wash, shared across every reader via the
  // `reader_eye_care` pref (see ReaderProvider). 0.0 = off.
  double _eyeCare = 0.0;
  PdfColorMode _colorMode = PdfColorMode.light;
  FitPolicy _fitPolicy = FitPolicy.BOTH;
  PdfViewMode _viewMode = PdfViewMode.paged;

  // Tap vs. scroll discrimination for the focus-mode toggle.
  Offset? _touchStart;
  DateTime? _touchStartAt;

  Timer? _saveTimer;
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 30);

  int get _bookId => widget.bookId ?? stableBookKey(widget.filePath);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _restoreState();
    _streakPingTimer = Timer.periodic(_streakPingInterval, (_) {
      StreakService.instance.recordActiveSeconds(_streakPingInterval.inSeconds);
    });
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
    // neither ever saved (first PDF ever opened), default to the app's own
    // light/dark setting rather than always opening on a white page.
    final savedMode = prefs.getInt('reader_pdf_color_mode');
    final legacyDarkGutter = prefs.getBool('reader_pdf_dark_gutter');
    if (savedMode != null) {
      _colorMode = PdfColorMode.values[savedMode.clamp(0, PdfColorMode.values.length - 1)];
    } else if (legacyDarkGutter != null) {
      _colorMode = legacyDarkGutter ? PdfColorMode.night : PdfColorMode.light;
    } else {
      _colorMode = AppTheme.instance.isDark ? PdfColorMode.night : PdfColorMode.light;
    }
    // Paged (sideways, one page per swipe) is the default — it's how a normal
    // book PDF reads. Scroll mode is what rescues very tall pages; see
    // [PdfViewMode].
    _viewMode = PdfViewMode.values[(prefs.getInt('reader_pdf_view_mode') ?? 0).clamp(0, PdfViewMode.values.length - 1)];
    // BOTH is the default in paged mode: it always shows the whole page, which
    // single-page horizontal swiping needs (there's no way to scroll to the
    // rest of a page that WIDTH left below the fold). In scroll mode that
    // constraint is gone and WIDTH is the useful one, which is why
    // [_setViewMode] moves the fit across with the mode.
    _fitPolicy = (prefs.getBool('reader_pdf_fit_width') ?? false) ? FitPolicy.WIDTH : FitPolicy.BOTH;
    _applyBrightness();
    _reflowEpubPath = await PdfReflowService.instance.cachedReflowEpubPath(widget.filePath);
    if (mounted) setState(() {});
  }

  Future<void> _switchToTextView() async {
    final epubPath = _reflowEpubPath;
    if (epubPath == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(preferFixedPrefKey(_bookId));
    await _saveProgress();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
          child: ReaderScreen(
            bookPath: epubPath,
            bookId: _bookId,
            bookTitle: widget.title,
            originalPdfPath: widget.filePath,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _streakPingTimer?.cancel();
    _releaseBrightness();
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
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
    if (_totalPages > 0) {
      await prefs.setDouble('book_${_bookId}_progress', (_currentPage + 1) / _totalPages);
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
  void _onPageChanged(int? page, int? total) {
    final p = page ?? 0;
    final t = total ?? _totalPages;
    log('📄 PDF page=${p + 1}/$t');
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
    _controller?.setPage(target);
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
    // Toggling night mode rebuilds the native view (nightMode is read once at
    // creation — see the PDFView key), so remember where we are or the rebuild
    // would drop us back at page one. Sepia is a pure Flutter overlay and needs
    // no rebuild, but pinning the page here is harmless either way.
    setState(() {
      _initialPage = _currentPage;
      _colorMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_pdf_color_mode', mode.index);
  }

  Future<void> _setFit(FitPolicy fit) async {
    if (_fitPolicy == fit) return;
    setState(() {
      _initialPage = _currentPage;
      _fitPolicy = fit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_pdf_fit_width', fit == FitPolicy.WIDTH);
  }

  Future<void> _setViewMode(PdfViewMode mode) async {
    if (_viewMode == mode) return;
    // Each mode only really works with one of the two fits (see
    // [PdfViewMode]), so switching brings the fit along rather than leaving
    // the reader in the broken pairing — scroll + whole-page would still
    // shrink a tall page to nothing, and paged + fit-width would still cut
    // one off below the fold. It's still a plain setting afterwards: the fit
    // tiles stay live, so anyone who wants the other pairing can pick it.
    final fit = mode == PdfViewMode.scroll ? FitPolicy.WIDTH : FitPolicy.BOTH;
    setState(() {
      _initialPage = _currentPage;
      _viewMode = mode;
      _fitPolicy = fit;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_pdf_view_mode', mode.index);
    await prefs.setBool('reader_pdf_fit_width', fit == FitPolicy.WIDTH);
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
          onSwitchToTextView: _reflowEpubPath != null ? _switchToTextView : null,
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
            if (page != null) _controller?.setPage(page);
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
    // The sheet speaks in 1-based page numbers, PDFView in 0-based indices.
    if (page != null) _controller?.setPage(page - 1);
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
                child: PDFView(
                  // nightMode and fitPolicy are read once when the native view
                  // is created, so changing either has to rebuild it — that's
                  // what varying the key does. defaultPage carries our place
                  // across that rebuild and across reopening the book. (Sepia
                  // isn't in the key: it's a Flutter overlay, not a render
                  // change, so switching to/from it mustn't reload the file.)
                  key: ValueKey('pdf_${nightMode}_${_fitPolicy.name}_${_viewMode.name}_$_initialPage'),
                  filePath: widget.filePath,
                  // Paged: one page per sideways swipe, like a real page turn.
                  // Vertical *paged* scrolling was the old default and read
                  // badly — the tail of the current page, a gap, then the top
                  // of the next one bleeding in, which looked like a border
                  // round the picture (it wasn't: a page's height rarely
                  // divides the screen evenly). Scroll mode below is different:
                  // it drops the snapping entirely so pages run together as
                  // one continuous strip, which is what a tall webtoon page
                  // needs.
                  swipeHorizontal: _viewMode == PdfViewMode.paged,
                  // Only snap/fling to page boundaries when pages *are* the
                  // unit of movement. In scroll mode they'd fight the free
                  // vertical scroll that makes a tall page readable — and on
                  // iOS pageFling is what picks a paging controller over
                  // continuous scrolling, so it has to go there too.
                  //
                  // `autoSpacing` is deliberately left at its default: on
                  // Android it only controls the gap between pages, but on
                  // iOS this same flag is wired to PDFKit's `autoScales`, so
                  // turning it off to close that gap would stop the page
                  // fitting the screen at all there.
                  pageSnap: _viewMode == PdfViewMode.paged,
                  pageFling: _viewMode == PdfViewMode.paged,
                  // Night mode inverts the rendered page to light-on-dark — the
                  // "göz goraýyş" dark reading the user asked for. It's ideal
                  // for text PDFs (black-on-white becomes white-on-black) and
                  // poor for scanned/manga pages (they become photo negatives),
                  // which is why it's an opt-in mode, not the default. PDFium's
                  // nightMode is Android-only; on iOS it does nothing, so night
                  // there degrades to the plain page on a dark gutter.
                  nightMode: nightMode,
                  defaultPage: _initialPage,
                  fitPolicy: _fitPolicy,
                  backgroundColor: bg,
                  onViewCreated: (c) => _controller = c,
                  onRender: (pages) => setState(() {
                    _totalPages = pages ?? 0;
                    _isLoading = false;
                  }),
                  onPageChanged: _onPageChanged,
                  onError: (error) => setState(() {
                    // The raw exception (often a bare "PlatformException(...)")
                    // is developer noise, not something a reader should have to
                    // parse — log it and show a plain-language message instead.
                    log('❌ PDF open error: $error');
                    _error = ReaderStrings.pdfOpenError;
                    _isLoading = false;
                  }),
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
