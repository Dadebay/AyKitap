import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/cbz_page_cache.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/stable_hash.dart';
import '../widgets/cbz_settings_sheet.dart';
import '../widgets/pdf_bookmarks_sheet.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_go_to_page_sheet.dart';
import '../widgets/reader_top_bar.dart';

/// File extensions a CBZ page can be. Top-level (not a class member) so
/// [_extractCbzOnIsolate] can see it without capturing `this` — see that
/// function's doc for why that matters.
const _cbzImageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

/// Orders "page2.jpg" before "page10.jpg" — plain string sort would put
/// "page10" first, scrambling any chapter with 10+ pages. Top-level for the
/// same reason as [_cbzImageExtensions].
int _compareCbzPagesNaturally(String a, String b) {
  final pattern = RegExp(r'\d+|\D+');
  final partsA = pattern.allMatches(a).map((m) => m.group(0)!).toList();
  final partsB = pattern.allMatches(b).map((m) => m.group(0)!).toList();
  for (var i = 0; i < partsA.length && i < partsB.length; i++) {
    final numA = int.tryParse(partsA[i]);
    final numB = int.tryParse(partsB[i]);
    if (numA != null && numB != null) {
      if (numA != numB) return numA.compareTo(numB);
    } else {
      final c = partsA[i].compareTo(partsB[i]);
      if (c != 0) return c;
    }
  }
  return partsA.length.compareTo(partsB.length);
}

Future<List<String>> _sortedCbzPageFiles(Directory cacheDir) async {
  final entries = await cacheDir.list().toList();
  final files = entries.whereType<File>().where((f) {
    final dot = f.path.lastIndexOf('.');
    return dot != -1 && _cbzImageExtensions.contains(f.path.substring(dot).toLowerCase());
  }).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files.map((f) => f.path).toList();
}

/// Unpacks a CBZ's pages onto disk: reads the whole zip into memory, decodes
/// it, and writes one file per page. Runs on a background isolate spawned by
/// [_CbzReaderScreenState._extract] via [Isolate.run] — a 200-500MB scanned
/// manga volume decoded on the UI isolate froze the loading animation and
/// could OOM low-RAM devices, since none of this work yields back to the
/// event loop in a way that keeps the UI responsive.
///
/// Deliberately top-level and free of any State/BuildContext reference:
/// `Isolate.run`'s closure can only capture plain, isolate-sendable data
/// (the `(zipPath, cacheDirPath)` strings below), never `this` or `widget` —
/// capturing either would drag the whole Flutter State object into the
/// isolate-message graph and fail at runtime. [cacheDirPath] is resolved by
/// the caller beforehand for the same reason: getApplicationSupportDirectory()
/// goes through a platform channel, which isn't available off the main
/// isolate without extra plugin-side setup this app doesn't have.
Future<(List<String> pagePaths, bool noImages)> _extractCbzOnIsolate(
  (String zipPath, String cacheDirPath) args,
) async {
  final cacheDir = Directory(args.$2);
  final marker = File('${cacheDir.path}/.done');

  if (await marker.exists()) {
    final existing = await _sortedCbzPageFiles(cacheDir);
    if (existing.isNotEmpty) return (existing, false);
  }

  if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
  await cacheDir.create(recursive: true);

  final bytes = await File(args.$1).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);

  final imageEntries = archive.files.where((f) {
    if (!f.isFile) return false;
    final dot = f.name.lastIndexOf('.');
    if (dot == -1) return false;
    return _cbzImageExtensions.contains(f.name.substring(dot).toLowerCase());
  }).toList()
    ..sort((a, b) => _compareCbzPagesNaturally(a.name, b.name));

  if (imageEntries.isEmpty) return (const <String>[], true);

  final paths = <String>[];
  for (var i = 0; i < imageEntries.length; i++) {
    final entry = imageEntries[i];
    final data = entry.readBytes();
    if (data == null) continue;
    final ext = entry.name.substring(entry.name.lastIndexOf('.'));
    final pagePath = '${cacheDir.path}/${i.toString().padLeft(5, '0')}$ext';
    await File(pagePath).writeAsBytes(data, flush: true);
    paths.add(pagePath);
  }

  if (paths.isEmpty) return (const <String>[], true);

  await marker.create();
  return (paths, false);
}

/// Reader for a CBZ — a comic/manga chapter packaged as a zip of page images,
/// with no text, layout or table of contents of its own (that's what tells it
/// apart from an EPUB, and why it doesn't get [ReaderScreen]'s text-driven
/// features either). Styled to match [PdfReaderScreen] as closely as the
/// format allows, down to reusing its bottom bar, bookmarks sheet and
/// go-to-page sheet verbatim — both are "a stack of pages with no reflowable
/// text", they just draw a page differently.
///
/// Pages are drawn by Flutter's own `Image.file` inside a zoomable
/// [InteractiveViewer], rather than a platform view like the PDF reader uses —
/// there's no comparable native "comic viewer" component in this project, and
/// decoded images are simple enough for Flutter to draw directly.
class CbzReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  /// Stable id used to scope this book's saved page and bookmarks — see
  /// [PdfReaderScreen.bookId] for why this exists instead of just hashing the
  /// path inline.
  final int? bookId;

  const CbzReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.bookId,
  });

  @override
  State<CbzReaderScreen> createState() => _CbzReaderScreenState();
}

class _CbzReaderScreenState extends State<CbzReaderScreen> {
  // Created synchronously (no `late`) so an early back-press — before the
  // async prefs/extraction work below ever runs — can't dispose() a
  // controller that was never initialized. It starts at page 0 and is
  // corrected to the restored page once extraction resolves the real page
  // count; see _applyRestoredPage.
  final PageController _pageController = PageController();

  List<String> _pagePaths = const [];
  int _currentPage = 0; // 0-based
  int _initialPage = 0;
  int? _lastLoggedPage;
  bool _isLoading = true;
  String? _error;

  bool _showControls = true;
  double _brightness = 1.0;
  bool _darkGutter = true;
  BoxFit _fit = BoxFit.contain;

  Timer? _saveTimer;
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 30);

  int get _bookId => widget.bookId ?? stableBookKey(widget.filePath);
  int get _totalPages => _pagePaths.length;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bootstrap();
    _streakPingTimer = Timer.periodic(_streakPingInterval, (_) {
      StreakService.instance.recordActiveSeconds(_streakPingInterval.inSeconds);
    });
  }

  Future<void> _bootstrap() async {
    await BookmarksStore.instance.load();
    final prefs = await SharedPreferences.getInstance();
    _initialPage = prefs.getInt('book_${_bookId}_cbz_page') ?? 0;
    _currentPage = _initialPage;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    _darkGutter = prefs.getBool('reader_cbz_dark_gutter') ?? true;
    _fit = (prefs.getBool('reader_cbz_fit_cover') ?? false) ? BoxFit.cover : BoxFit.contain;
    await _applyBrightness();
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
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_initialPage);
      }
    });
  }

  /// Unpacks the zip to one image file per page, in a folder keyed by this
  /// file's own path — a second open of the same book reuses it instead of
  /// re-extracting. A `.done` marker is what "reuse" checks for, so a run that
  /// got killed mid-extraction is redone rather than served half-finished.
  /// The actual decode/write work happens off the UI isolate — see
  /// [_extractCbzOnIsolate] for why.
  Future<void> _extract() async {
    try {
      final cacheDir = await cbzPageCacheDirFor(widget.filePath);
      // Captured as plain Strings, not `cacheDir`/`widget` themselves — see
      // _extractCbzOnIsolate's doc on what Isolate.run's closure may capture.
      final zipPath = widget.filePath;
      final cacheDirPath = cacheDir.path;
      final (pages, noImages) = await Isolate.run(() => _extractCbzOnIsolate((zipPath, cacheDirPath)));

      if (!mounted) return;
      if (noImages) {
        setState(() {
          _error = ReaderStrings.cbzNoImagesError;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _pagePaths = pages;
        _isLoading = false;
        _applyRestoredPage();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _saveTimer?.cancel();
    _streakPingTimer?.cancel();
    _releaseBrightness();
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    super.dispose();
  }

  // ── Brightness (TZ §12.4) ────────────────────────────────────────────────
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

  Future<void> _setBrightness(double v) async {
    setState(() => _brightness = v.clamp(0.1, 1.0));
    await _applyBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  Future<void> _setGutter(bool dark) async {
    setState(() => _darkGutter = dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_cbz_dark_gutter', dark);
  }

  Future<void> _setFit(BoxFit fit) async {
    setState(() => _fit = fit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_cbz_fit_cover', fit == BoxFit.cover);
  }

  // ── Progress persistence ─────────────────────────────────────────────────
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_${_bookId}_cbz_page', _currentPage);
    if (_totalPages > 0) {
      await prefs.setDouble('book_${_bookId}_progress', (_currentPage + 1) / _totalPages);
    }
  }

  // ── Page changes ─────────────────────────────────────────────────────────
  void _onPageChanged(int page) {
    if (_lastLoggedPage != null && page > _lastLoggedPage!) {
      StreakService.instance.recordPageRead(count: (page - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = page;
    setState(() => _currentPage = page);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void _jumpToProgress(double value) {
    if (_totalPages <= 0) return;
    final target = (value * (_totalPages - 1)).round().clamp(0, _totalPages - 1);
    _pageController.jumpToPage(target);
  }

  // ── Bookmarks (TZ §12.1) ─────────────────────────────────────────────────
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

  // ── Sheets ───────────────────────────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (_, setSheetState) => CbzSettingsSheet(
          darkGutter: _darkGutter,
          brightness: _brightness,
          fit: _fit,
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
            if (page != null && page < _totalPages) _pageController.jumpToPage(page);
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
    if (page != null) _pageController.jumpToPage(page - 1);
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    final bg = _darkGutter ? const Color(0xFF1C1C1E) : Colors.white;
    final inFocus = !_showControls && !_isLoading && _error == null;
    final focusColor = _darkGutter ? Colors.white38 : Colors.black38;
    // Decode target for each page image. Without this, Image.file decodes a
    // scanned page at its native resolution (often 3000-4000px on a side) —
    // full size for every page PageView keeps around (current + neighbours),
    // which is what caused the stutter/OOM on lower-RAM devices. 2x the
    // screen's physical pixels leaves headroom for InteractiveViewer's
    // maxScale: 4 zoom without needing a re-decode.
    final pageCacheWidth = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context) * 2).round();

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (_error == null && !_isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalPages,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, i) => ColoredBox(
                    color: bg,
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: Image.file(File(_pagePaths[i]), fit: _fit, cacheWidth: pageCacheWidth),
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
                        ReaderStrings.cbzExtracting,
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
                          ReaderStrings.cbzOpenError(_error!),
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

          // ── Focus-mode page number ─────────────────────────────────────
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
