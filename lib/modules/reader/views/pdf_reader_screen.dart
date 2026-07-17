import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stable_hash.dart';
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
  double _brightness = 1.0;
  bool _darkGutter = true;
  FitPolicy _fitPolicy = FitPolicy.BOTH;

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
    _darkGutter = prefs.getBool('reader_pdf_dark_gutter') ?? true;
    // BOTH is the default: it always shows the whole page, which single-page
    // horizontal swiping needs (there's no way to scroll to the rest of a page
    // that WIDTH left below the fold). WIDTH is opt-in, for someone who'd
    // rather fill the width and accept a taller page running off-screen.
    _fitPolicy = (prefs.getBool('reader_pdf_fit_width') ?? false) ? FitPolicy.WIDTH : FitPolicy.BOTH;
    _applyBrightness();
    if (mounted) setState(() {});
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
      if (_brightness >= 1.0) {
        await ScreenBrightness().resetApplicationScreenBrightness();
      } else {
        await ScreenBrightness().setApplicationScreenBrightness(_brightness.clamp(0.0, 1.0));
      }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? ReaderStrings.bookmarkAdded : ReaderStrings.bookmarkRemoved),
      duration: const Duration(seconds: 1),
    ));
  }

  Future<void> _setBrightness(double v) async {
    setState(() => _brightness = v.clamp(0.1, 1.0));
    await _applyBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  Future<void> _setGutter(bool dark) async {
    if (_darkGutter == dark) return;
    // The native view is rebuilt for this (see the PDFView key), so remember
    // where we are or the rebuild would drop us back at page one.
    setState(() {
      _initialPage = _currentPage;
      _darkGutter = dark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_pdf_dark_gutter', dark);
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
          darkGutter: _darkGutter,
          brightness: _brightness,
          fitPolicy: _fitPolicy,
          onGutterChanged: (v) async {
            await _setGutter(v);
            setSheetState(() {});
          },
          onBrightnessChanged: (v) async {
            await _setBrightness(v);
            setSheetState(() {});
          },
          onFitChanged: (v) async {
            await _setFit(v);
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
    final bg = _darkGutter ? const Color(0xFF1C1C1E) : Colors.white;
    final inFocus = !_showControls && !_isLoading && _error == null;
    final focusColor = _darkGutter ? Colors.white38 : Colors.black38;

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
                  // across that rebuild and across reopening the book.
                  key: ValueKey('pdf_${_darkGutter}_${_fitPolicy.name}_$_initialPage'),
                  filePath: widget.filePath,
                  // One page per swipe, like a real page turn — not a
                  // continuous vertical scroll. Vertical mode showed the tail
                  // of the current page, then a gap, then the top of the next
                  // one bleeding into view, which is what read as "there's a
                  // border/frame around the picture": it wasn't a border, it
                  // was the *next page* peeking in because a manga page's
                  // height doesn't divide the screen evenly.
                  swipeHorizontal: true,
                  // nightMode intentionally left at its default (false) rather
                  // than tied to _darkGutter: PDFium's nightMode colour-inverts
                  // the rendered page itself (not just the surrounding gutter),
                  // which turns a scanned/manga page into a photo negative —
                  // and it's Android-only, so on iOS the toggle would silently
                  // do nothing at all. _darkGutter only drives backgroundColor
                  // below, which is what "koyu zemin" actually promises.
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
                          color: _darkGutter ? Colors.white70 : Colors.black54,
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
                            color: _darkGutter ? Colors.white70 : Colors.black54,
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
