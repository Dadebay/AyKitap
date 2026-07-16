import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sakura_epub/sakura_epub.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/streak_service.dart';

enum ReaderThemeMode { white, sepia, dark, black }

/// TZ §12.4 — the reader body fonts offered in the settings sheet. Each maps to
/// a bundled font file that's injected into the epub WebView (see
/// [_applyReaderFont]) and a matching Flutter family for the sheet's preview.
enum ReaderFontFamily { sanFrancisco, arial, notoSerif, openSans }

/// TZ §12.2 — the six page-change styles shown in the reference panel.
/// sakura_epub only distinguishes paginated vs. scrolled natively, so the
/// scroll option maps to [EpubFlow.scrolled] and every other option to
/// [EpubFlow.paginated]; the distinct curl/overlay/shift animations are a
/// visual layer epub.js doesn't expose, so they currently share the standard
/// slide behaviour while still being remembered as the user's preference.
enum ReaderPageTransition { slide, curl, overlay, scroll, shift, none }

class ReaderProvider extends ChangeNotifier {
  // ── Epub controller (low-level WebView bridge) ──────────────────────────
  final EpubController epubController = EpubController();

  // ── Page state ───────────────────────────────────────────────────────────
  int _currentPage = 0;
  int _totalPages = 0;
  int? _lastLoggedPage;
  double _progress = 0.0;
  String _currentCfi = '';
  bool _isAtLastPage = false;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  double get progress => _progress;
  String get currentCfi => _currentCfi;
  bool get isAtLastPage => _isAtLastPage;

  // ── Loading state ────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isProgressSaving = false;

  bool get isLoading => _isLoading;
  bool get isProgressSaving => _isProgressSaving;

  // ── Chapters ─────────────────────────────────────────────────────────────
  List<EpubChapter> _chapters = [];
  List<EpubChapter> get chapters => _chapters;

  /// Spine href of the page on screen, reported by [onRelocated].
  String _currentHref = '';

  /// TZ §12.1 — the chapter name shown in the reader's top bar. Resolved by
  /// matching the current page's spine href against the TOC (including nested
  /// subitems); null while the position is still unknown or the href isn't in
  /// the TOC, so the caller can fall back to the book title.
  String? get currentChapterTitle {
    if (_currentHref.isEmpty || _chapters.isEmpty) return null;
    final current = _normalizeHref(_currentHref);
    if (current.isEmpty) return null;

    String? walk(List<EpubChapter> list) {
      // Depth-first, deepest match wins: a subitem is more specific than the
      // top-level entry that contains it.
      for (final c in list) {
        final fromChild = walk(c.subitems);
        if (fromChild != null) return fromChild;
        if (_normalizeHref(c.href) == current && c.title.trim().isNotEmpty) {
          return c.title.trim();
        }
      }
      return null;
    }

    return walk(_chapters);
  }

  /// Whether [chapter] is the one currently on screen — used by the chapter
  /// list to highlight where the reader is. Compares on the normalized href
  /// (see [_normalizeHref]); an anchor-only difference still counts as the
  /// same chapter file.
  bool isChapterCurrent(EpubChapter chapter) {
    if (_currentHref.isEmpty || chapter.href.isEmpty) return false;
    return _normalizeHref(chapter.href) == _normalizeHref(_currentHref);
  }

  /// TOC hrefs and spine hrefs often disagree on anchors (`#id`), query
  /// strings and directory prefixes (`OEBPS/text/ch1.xhtml` vs `ch1.xhtml`),
  /// so compare on the bare file name only.
  String _normalizeHref(String href) {
    var h = href.split('#').first.split('?').first;
    final slash = h.lastIndexOf('/');
    if (slash != -1) h = h.substring(slash + 1);
    return h.trim();
  }

  // ── UI state ─────────────────────────────────────────────────────────────
  // Chrome starts visible so the controls are discoverable when a book opens;
  // tapping the page hides it for distraction-free reading and brings it back.
  bool _showControls = true;
  bool get showControls => _showControls;

  String _selectedText = '';
  String? _selectedCfi;
  Rect? _selectionRect;

  String get selectedText => _selectedText;
  String? get selectedCfi => _selectedCfi;
  Rect? get selectionRect => _selectionRect;
  bool get hasSelection => _selectedText.isNotEmpty;

  // ── Theme & font ─────────────────────────────────────────────────────────
  ReaderThemeMode _themeMode = ReaderThemeMode.white;
  ReaderFontFamily _fontFamily = ReaderFontFamily.sanFrancisco;
  double _fontSize = 18.0;
  double _lineSpacing = 1.5;
  // TZ §12.4 — screen dimming, 0.1 (darkest) … 1.0 (full). Applied as an
  // overlay in the reader view, independent of the OS brightness.
  double _brightness = 1.0;

  ReaderThemeMode get themeMode => _themeMode;
  ReaderFontFamily get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;
  double get brightness => _brightness;

  EpubTheme get currentEpubTheme => _buildEpubTheme();

  // ── Page transition & reading direction (TZ §12.2) ────────────────────────
  ReaderPageTransition _pageTransition = ReaderPageTransition.slide;
  bool _leftHandMode = false;

  ReaderPageTransition get pageTransition => _pageTransition;
  bool get leftHandMode => _leftHandMode;

  // ── Bookmarks (TZ §12.1) ──────────────────────────────────────────────────
  // Held in the app-wide [BookmarksStore] rather than locally, so the profile
  // can list every book's marks while the reader shows only this book's.
  List<Bookmark> get bookmarks => BookmarksStore.instance.forBook(_bookId ?? -1);
  bool get isCurrentPageBookmarked =>
      _bookId != null && _currentCfi.isNotEmpty && BookmarksStore.instance.isBookmarked(_bookId!, _currentCfi);

  // ── Book info ─────────────────────────────────────────────────────────────
  int? _bookId;
  String _bookTitle = '';
  Timer? _saveTimer;

  // ── Streak ping (TZ §9.1: "Her 30 sek-de server-e ping iberilýär") ────────
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize({required int bookId, String bookTitle = ''}) async {
    _bookId = bookId;
    _bookTitle = bookTitle;
    _isLoading = true;
    notifyListeners();

    // Bookmarks live app-wide; make sure they're in memory before the top bar
    // asks whether this page is marked.
    await BookmarksStore.instance.load();

    final prefs = await SharedPreferences.getInstance();
    _progress = prefs.getDouble('book_${bookId}_progress') ?? 0.0;
    _currentPage = prefs.getInt('book_${bookId}_page') ?? 0;
    _lastLoggedPage = null;

    final savedTheme = prefs.getInt('reader_theme') ?? 0;
    _themeMode = ReaderThemeMode.values[savedTheme.clamp(0, ReaderThemeMode.values.length - 1)];

    final savedFont = prefs.getInt('reader_font') ?? 0;
    _fontFamily = ReaderFontFamily.values[savedFont.clamp(0, ReaderFontFamily.values.length - 1)];

    _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    _lineSpacing = prefs.getDouble('reader_line_spacing') ?? 1.5;
    _brightness = prefs.getDouble('reader_brightness') ?? 1.0;
    // Apply the saved reading brightness to the device screen now that we're
    // in the reader (restored to system brightness again on close).
    _applyReaderBrightness();

    final savedTransition = prefs.getInt('reader_page_transition') ?? 0;
    _pageTransition = ReaderPageTransition.values[savedTransition.clamp(0, ReaderPageTransition.values.length - 1)];
    _leftHandMode = prefs.getBool('reader_left_hand') ?? false;

    notifyListeners();

    _streakPingTimer?.cancel();
    _streakPingTimer = Timer.periodic(_streakPingInterval, (_) {
      StreakService.instance.recordActiveSeconds(_streakPingInterval.inSeconds);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Epub viewer callbacks
  // ─────────────────────────────────────────────────────────────────────────

  void onEpubLoaded() {
    log('📖 EPUB loaded');
    _isLoading = false;
    notifyListeners();

    // Push the saved page-change style into the freshly-created rendition —
    // it only lives in the webview, so it has to be re-applied per book.
    epubController.setPageTransition(mode: _pageTransition.name);
    if (_pageTransition == ReaderPageTransition.scroll) {
      epubController.setFlow(flow: EpubFlow.scrolled);
    }

    // The chosen body font is a WebView @font-face, so it also has to be
    // (re)injected each time a book's rendition is created.
    _applyReaderFont();

    // Restore reading position
    if (_progress > 0.0) {
      Future.delayed(const Duration(milliseconds: 600), () {
        epubController.toProgressPercentage(_progress);
      });
    }
  }

  void onChaptersLoaded(List<EpubChapter> chapters) {
    log('📑 Chapters loaded: ${chapters.length}');
    _chapters = chapters;
    notifyListeners();
  }

  void onRelocated(EpubLocation location) {
    _progress = location.progress;
    _currentCfi = location.startCfi;
    _currentHref = location.href ?? '';
    notifyListeners();

    // Debounced save
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  void onPageChanged(int current, int total) {
    _currentPage = current;
    _totalPages = total;
    _isAtLastPage = current >= total - 1;
    // Only forward turns count as "pages read" — and the very first callback
    // after a load/position-restore is skipped so jumping back into a book
    // isn't logged as having read every page up to that point.
    if (_lastLoggedPage != null && current > _lastLoggedPage!) {
      StreakService.instance.recordPageRead(count: (current - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = current;
    notifyListeners();
  }

  void onTextSelected(EpubTextSelection selection) {
    _selectedText = selection.selectedText;
    _selectedCfi = selection.selectionCfi;
    notifyListeners();
  }

  void onSelection(String text, String? cfi, Rect? selectionRect, Rect? viewRect) {
    _selectedText = text;
    _selectedCfi = cfi;
    _selectionRect = selectionRect;
    notifyListeners();
  }

  void onDeselection() {
    _selectedText = '';
    _selectedCfi = null;
    _selectionRect = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI actions
  // ─────────────────────────────────────────────────────────────────────────

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void hideControls() {
    if (_showControls) {
      _showControls = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    epubController.clearSelection();
    _selectedText = '';
    _selectedCfi = null;
    _selectionRect = null;
    notifyListeners();
  }

  void nextPage() => epubController.next();
  void prevPage() => epubController.prev();

  void goToChapter(EpubChapter chapter) {
    final target = chapter.id.isNotEmpty && !chapter.href.contains('#')
        ? '${chapter.href}#${chapter.id}'
        : chapter.href;
    epubController.display(cfi: target);
  }

  void goToCfi(String cfi) => epubController.display(cfi: cfi);

  // ─────────────────────────────────────────────────────────────────────────
  // Settings
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setTheme(ReaderThemeMode mode) async {
    _themeMode = mode;
    epubController.updateTheme(theme: _buildEpubTheme());
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme', mode.index);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(12.0, 28.0);
    epubController.setFontSize(fontSize: _fontSize);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
  }

  Future<void> setFontFamily(ReaderFontFamily family) async {
    _fontFamily = family;
    await _applyReaderFont();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_font', family.index);
  }

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing.clamp(1.0, 2.5);
    epubController.updateTheme(theme: _buildEpubTheme());
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_line_spacing', _lineSpacing);
  }

  Future<void> setBrightness(double value) async {
    _brightness = value.clamp(0.1, 1.0);
    notifyListeners();
    await _applyReaderBrightness();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_brightness', _brightness);
  }

  /// Drives the actual device screen brightness (TZ §12.4). At full brightness
  /// we release control so the reader follows the system setting; below full,
  /// the app screen is dimmed to the chosen level. All app-scoped, so it's
  /// undone automatically when the app backgrounds — and explicitly on close.
  Future<void> _applyReaderBrightness() async {
    try {
      if (_brightness >= 1.0) {
        await ScreenBrightness().resetApplicationScreenBrightness();
      } else {
        await ScreenBrightness().setApplicationScreenBrightness(_brightness.clamp(0.0, 1.0));
      }
    } catch (e) {
      log('❌ Brightness error: $e');
    }
  }

  Future<void> _releaseBrightness() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      log('❌ Brightness reset error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Page transition & reading direction (TZ §12.2)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setPageTransition(ReaderPageTransition transition) async {
    _pageTransition = transition;
    // Two levers: `flow` picks paginated vs scrolled reading, and the custom
    // animation layer in epubView.js plays the chosen tween on each turn.
    epubController.setFlow(
      flow: transition == ReaderPageTransition.scroll ? EpubFlow.scrolled : EpubFlow.paginated,
    );
    epubController.setPageTransition(mode: transition.name);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_page_transition', transition.index);
  }

  Future<void> toggleLeftHand() async {
    _leftHandMode = !_leftHandMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reader_left_hand', _leftHandMode);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bookmarks (TZ §12.1)
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggles a bookmark at the current reading position (CFI). Returns true
  /// if a bookmark was added, false if one was removed.
  Future<bool> toggleBookmark() async {
    if (_bookId == null || _currentCfi.isEmpty) return false;
    final added = await BookmarksStore.instance.toggle(
      bookId: _bookId!,
      bookTitle: _bookTitle,
      cfi: _currentCfi,
      chapterTitle: currentChapterTitle ?? '',
      progress: _progress,
    );
    notifyListeners();
    return added;
  }

  Future<void> removeBookmark(String id) async {
    await BookmarksStore.instance.remove(id);
    notifyListeners();
  }

  void goToBookmark(String cfi) => epubController.display(cfi: cfi);

  // ─────────────────────────────────────────────────────────────────────────
  // In-book search (TZ §12.3)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<EpubSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    return epubController.search(query: query.trim());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme builder
  // ─────────────────────────────────────────────────────────────────────────

  // ── Reader body font (TZ §12.4) ───────────────────────────────────────────
  // The epub renders in a WebView, so the chosen font can't come from Flutter's
  // registered families — it's read from assets, base64-encoded and injected as
  // an @font-face. The css/asset names line up so the injected face and the
  // theme's `font-family` rule refer to the same family.

  static String _fontCssName(ReaderFontFamily f) => switch (f) {
        ReaderFontFamily.sanFrancisco => 'SanFrancisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'NotoSerif',
        ReaderFontFamily.openSans => 'OpenSans',
      };

  static String _fontAsset(ReaderFontFamily f) => switch (f) {
        ReaderFontFamily.sanFrancisco => 'assets/fonts/SF-Pro-Text-Regular.otf',
        ReaderFontFamily.arial => 'assets/fonts/Arial-Regular.ttf',
        ReaderFontFamily.notoSerif => 'assets/fonts/NotoSerif-Regular.ttf',
        ReaderFontFamily.openSans => 'assets/fonts/OpenSans-Regular.ttf',
      };

  Future<void> _applyReaderFont() async {
    final family = _fontFamily;
    final asset = _fontAsset(family);
    try {
      final data = await rootBundle.load(asset);
      final b64 = base64Encode(data.buffer.asUint8List());
      epubController.setFontFamily(
        fontFamily: _fontCssName(family),
        fontBase64: b64,
        fontMimeType: asset.endsWith('.otf') ? 'font/opentype' : 'font/truetype',
      );
    } catch (e) {
      log('❌ Font apply error: $e');
    }
  }

  EpubTheme _buildEpubTheme() {
    final fontName = _fontCssName(_fontFamily);
    final css = _readerCss(fontName);
    return switch (_themeMode) {
      ReaderThemeMode.white => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
          foregroundColor: const Color(0xFF000000),
          customCss: css,
        ),
      ReaderThemeMode.sepia => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFf5ebda)),
          foregroundColor: const Color(0xFF3E3329),
          customCss: css,
        ),
      ReaderThemeMode.dark => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
          foregroundColor: const Color(0xFFFFFFFF),
          customCss: css,
        ),
      ReaderThemeMode.black => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF000000)),
          foregroundColor: const Color(0xFFABAAB2),
          customCss: css,
        ),
    };
  }

  /// sakura_epub's `customCss` is a map of **CSS selector → { property: value }**
  /// (its `updateTheme` merges each selector's object into the epub.js theme
  /// rules). The old flat `{ 'font-family': … }` shape was silently ignored
  /// because those keys were treated as selectors with string values.
  ///
  /// The `img` / `svg` rules keep pictures — especially full-page cover art —
  /// centred and scaled to fit the page instead of spilling off to one side.
  Map<String, dynamic> _readerCss(String fontName) => {
        'body': {
          'font-family': fontName,
          'line-height': '$_lineSpacing',
          'padding-top': '40px',
          'padding-bottom': '40px',
        },
        'img': {
          'max-width': '100%',
          'max-height': '96vh',
          'height': 'auto',
          'display': 'block',
          'margin-left': 'auto',
          'margin-right': 'auto',
          'object-fit': 'contain',
        },
        'svg': {
          'max-width': '100%',
          'max-height': '96vh',
          'display': 'block',
          'margin-left': 'auto',
          'margin-right': 'auto',
        },
        // Cover pages: a body whose *only* content is one picture — either a
        // bare <img>/<svg> or one wrapped in a single <div> (Calibre emits
        // <body><div><svg><image/></svg></div>). The :only-child chain keeps
        // this from ever matching a text page that happens to contain an
        // illustration. Centring is done with flex rather than by forcing a
        // height, because these covers carry preserveAspectRatio="none" and
        // would stretch if the box's aspect ratio were changed.
        'body:has(> img:only-child), body:has(> svg:only-child), body:has(> div:only-child > img:only-child), body:has(> div:only-child > svg:only-child)': {
          'display': 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          'height': '100vh',
          'margin': '0',
          'padding': '0',
        },
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Progress persistence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveProgress() async {
    if (_bookId == null || _isProgressSaving) return;
    _isProgressSaving = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('book_${_bookId}_progress', _progress);
      await prefs.setInt('book_${_bookId}_page', _currentPage);
      log('💾 Progress saved: ${(_progress * 100).toStringAsFixed(1)}%');
    } catch (e) {
      log('❌ Save progress error: $e');
    } finally {
      _isProgressSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveAndClose() async {
    _saveTimer?.cancel();
    _streakPingTimer?.cancel();
    // Hand the screen brightness back to the system on the way out.
    await _releaseBrightness();
    await _saveProgress();
    _reset();
  }

  void _reset() {
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
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _streakPingTimer?.cancel();
    // Safety net: covers exit paths that don't route through saveAndClose.
    _releaseBrightness();
    super.dispose();
  }
}
