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
import '../../../core/services/notes_store.dart';
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

  /// Whether the one-time per-book rendition setup in [onEpubLoaded] has run.
  /// Guards against epub.js's `displayed` event, which fires on every
  /// navigation rather than once per book.
  bool _renditionConfigured = false;

  /// Set when the book fails to open (corrupt/unsupported file) or fails to
  /// render (epub.js's `displayError`), or when neither ever fires within
  /// [_loadTimeout] — see [_startLoadTimeout]. Without this a bad file left
  /// the reader stuck on the loading animation forever.
  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  Timer? _loadTimeoutTimer;
  static const _loadTimeout = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  bool get isProgressSaving => _isProgressSaving;

  // ── Chapters ─────────────────────────────────────────────────────────────
  List<EpubChapter> _chapters = [];
  List<EpubChapter> get chapters => _chapters;

  /// Spine href of the page on screen, reported by [onRelocated] — the *file*,
  /// e.g. `index_split_003.xhtml`.
  String _currentHref = '';

  /// Href of the TOC entry the reader is actually inside, anchor included,
  /// e.g. `index_split_003.xhtml#calibre_toc_991`. Resolved in the WebView
  /// (see resolveTocHref in epubView.js), because a spine file usually holds
  /// several chapters and only the anchor tells them apart.
  String _currentTocHref = '';

  /// TZ §12.1 — the chapter name shown in the reader's top bar; null while the
  /// position is still unknown or the entry isn't in the TOC, so the caller can
  /// fall back to the book title.
  String? get currentChapterTitle {
    if (_currentTocHref.isEmpty || _chapters.isEmpty) return null;
    final target = _tocKey(_currentTocHref);

    String? walk(List<EpubChapter> list) {
      for (final c in list) {
        if (_tocKey(c.href) == target && c.title.trim().isNotEmpty) {
          return c.title.trim();
        }
        final fromChild = walk(c.subitems);
        if (fromChild != null) return fromChild;
      }
      return null;
    }

    // Matching is exact, so at most one entry answers — no need to prefer the
    // deepest. Fall back to the file if the resolved entry isn't in the TOC.
    return walk(_chapters) ?? chapterTitleForHref(_currentHref);
  }

  /// The TOC title for a spine [href], or null when the href isn't in the TOC.
  /// Search results carry the href of the chapter they were found in, so this
  /// is how they get labelled.
  String? chapterTitleForHref(String? href) {
    if (href == null || href.isEmpty || _chapters.isEmpty) return null;
    final target = _normalizeHref(href);
    if (target.isEmpty) return null;

    String? walk(List<EpubChapter> list) {
      // Depth-first, deepest match wins: a subitem is more specific than the
      // top-level entry that contains it.
      for (final c in list) {
        final fromChild = walk(c.subitems);
        if (fromChild != null) return fromChild;
        if (_normalizeHref(c.href) == target && c.title.trim().isNotEmpty) {
          return c.title.trim();
        }
      }
      return null;
    }

    return walk(_chapters);
  }

  /// Whether [chapter] is the one currently on screen — used by the chapter
  /// list to highlight where the reader is. Anchor-exact: a book that packs
  /// twelve chapters into one xhtml would otherwise light all twelve up.
  bool isChapterCurrent(EpubChapter chapter) {
    if (_currentTocHref.isEmpty || chapter.href.isEmpty) return false;
    return _tocKey(chapter.href) == _tocKey(_currentTocHref);
  }

  /// TOC hrefs and spine hrefs often disagree on anchors (`#id`), query
  /// strings and directory prefixes (`OEBPS/text/ch1.xhtml` vs `ch1.xhtml`),
  /// so compare on the bare file name only. Deliberately drops the anchor —
  /// use [_tocKey] to tell chapters within a file apart.
  String _normalizeHref(String href) {
    var h = href.split('#').first.split('?').first;
    final slash = h.lastIndexOf('/');
    if (slash != -1) h = h.substring(slash + 1);
    return h.trim();
  }

  /// Identity of a single TOC entry: file name plus anchor. Two entries in the
  /// same file with different anchors are different chapters, which is exactly
  /// what [_normalizeHref] throws away.
  String _tocKey(String href) {
    final hash = href.indexOf('#');
    final anchor = hash == -1 ? '' : href.substring(hash + 1).split('?').first.trim();
    return '${_normalizeHref(href)}#$anchor';
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

  /// Bounds of the font-size slider, in CSS px. The reader's viewport is
  /// `width=device-width, initial-scale=1`, so 1 CSS px is 1 dp — these are
  /// directly comparable to Flutter font sizes.
  static const double minFontSize = 12.0;
  static const double maxFontSize = 28.0;

  /// First-run body size, used until the reader saves a choice of its own.
  /// Sits at the centre of [minFontSize]–[maxFontSize], so there's equal room
  /// to adjust either way, and matches what mainstream e-readers open at —
  /// comfortably above Material's 16 dp body text, which is sized for UI
  /// labels rather than for pages of prose.
  static const double defaultFontSize = 20.0;

  ReaderThemeMode _themeMode = ReaderThemeMode.white;
  ReaderFontFamily _fontFamily = ReaderFontFamily.sanFrancisco;
  double _fontSize = defaultFontSize;
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

  /// CFI the book was at when it was last closed, read once in [initialize]
  /// and handed to [EpubViewer.initialCfi] so the WebView opens directly at
  /// that spot — see [onEpubLoaded] for why this replaced the old
  /// progress-percentage jump.
  String _savedCfi = '';
  String get savedCfi => _savedCfi;

  /// A previously-saved `book.locations.save()` JSON blob (see
  /// [onLocationsGenerated]), read once in [initialize] and handed to
  /// [EpubViewer.initialLocations]. Lets the WebView skip epub.js's
  /// multi-second `book.locations.generate()` scan — without it, the page
  /// count and progress bar sat at 0 for the first few seconds of *every*
  /// open of the same book, not just the first.
  String? _savedLocationsJson;
  String? get savedLocationsJson => _savedLocationsJson;

  /// The catalogue book's `book_{seed}_{index}` id (TZ §12.7) — same string
  /// as [ReaderScreen.bookRef] — parsed once in [initialize] so [onEpubLoaded]
  /// can look up and redraw this book's saved highlights. Null for the
  /// user's own imported files, which carry no catalogue id and so can't
  /// have highlights (see ReaderScreen._bookSeedIndex / canAnnotate).
  (int, int)? _bookSeedIndex;

  // ── Streak ping (TZ §9.1: "Her 30 sek-de server-e ping iberilýär") ────────
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize({required int bookId, String bookTitle = '', String? bookRef}) async {
    _bookId = bookId;
    _bookTitle = bookTitle;
    _bookSeedIndex = _parseBookSeedIndex(bookRef);
    _isLoading = true;
    _loadFailed = false;
    // A new book gets a new rendition, so its setup has to run again.
    _renditionConfigured = false;
    notifyListeners();
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

    final savedTheme = prefs.getInt('reader_theme') ?? 0;
    _themeMode = ReaderThemeMode.values[savedTheme.clamp(0, ReaderThemeMode.values.length - 1)];

    final savedFont = prefs.getInt('reader_font') ?? 0;
    _fontFamily = ReaderFontFamily.values[savedFont.clamp(0, ReaderFontFamily.values.length - 1)];

    _fontSize = prefs.getDouble('reader_font_size') ?? defaultFontSize;
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

  /// Starts (or restarts) the "did the book ever load" watchdog. epub.js
  /// gives no guarantee that either `displayed` or `displayError` fires for
  /// every failure mode (a hung WebView, a book.open() that never settles),
  /// so this is the last-resort fallback that gets the reader out of an
  /// infinite loading spinner.
  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(_loadTimeout, () {
      if (_isLoading && !_loadFailed) {
        log('⏱️ EPUB load timeout — no displayed/error event within ${_loadTimeout.inSeconds}s');
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
    log('❌ EPUB failed to load');
    notifyListeners();
  }

  /// This fires on epub.js's `displayed` event, which is emitted on *every*
  /// navigation — each chapter tap included — not once per book. Everything
  /// below is per-rendition setup, so it's guarded to run only the first time.
  void onEpubLoaded() {
    _loadTimeoutTimer?.cancel();
    _isLoading = false;
    notifyListeners();

    if (_renditionConfigured) return;
    _renditionConfigured = true;
    log('📖 EPUB loaded — configuring rendition');

    // Push the saved page-change style into the freshly-created rendition —
    // it only lives in the webview, so it has to be re-applied per book.
    epubController.setPageTransition(mode: _pageTransition.name);
    if (_pageTransition == ReaderPageTransition.scroll) {
      epubController.setFlow(flow: EpubFlow.scrolled);
    }

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
    final seedIndex = _bookSeedIndex;
    if (seedIndex == null) return;
    await NotesStore.instance.load();
    final highlights = NotesStore.instance.highlightsForBook(bookSeed: seedIndex.$1, bookIndex: seedIndex.$2);
    for (final note in highlights) {
      epubController.addHighlight(cfi: note.cfi!, color: const Color(0xFFFFE082), opacity: 0.4);
    }
  }

  /// Parses the catalogue book's `book_{seed}_{index}` id into (seed, index),
  /// or null when there's no catalogue book to look up highlights for —
  /// mirrors ReaderScreen._bookSeedIndex, which resolves the same string for
  /// the "add highlight/note" side of this feature.
  (int, int)? _parseBookSeedIndex(String? ref) {
    if (ref == null) return null;
    final m = RegExp(r'^book_(\d+)_(\d+)$').firstMatch(ref);
    if (m == null) return null;
    return (int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  void onChaptersLoaded(List<EpubChapter> chapters) {
    log('📑 Chapters loaded: ${chapters.length}');
    _chapters = chapters;
    notifyListeners();
  }

  /// Fired once after epub.js finishes a fresh `book.locations.generate()`
  /// scan (never on a book opened from a cached [savedLocationsJson], since
  /// nothing new was generated then). Persisted so the next open of this book
  /// can skip that scan entirely via [EpubViewer.initialLocations].
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
    notifyListeners();

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
      StreakService.instance.recordPageRead(count: (current - _lastLoggedPage!).clamp(1, 5));
    }
    _lastLoggedPage = current;
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
    log('👉 goToChapter tapped="${chapter.title}" href=${chapter.href} → target=$target');
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
    _fontSize = size.clamp(minFontSize, maxFontSize);
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
    log('🔀 Page transition selected: ${transition.name}');
    _pageTransition = transition;
    // Three levers: `flow` picks paginated vs scrolled reading, the custom
    // animation layer in epubView.js plays the chosen tween on each turn, and
    // the reading CSS switches between the novel and manga layouts — see
    // [_isMangaLayout]. The theme has to be re-pushed because it's built from
    // the mode we just changed.
    epubController.setFlow(
      flow: transition == ReaderPageTransition.scroll ? EpubFlow.scrolled : EpubFlow.paginated,
    );
    epubController.setPageTransition(mode: transition.name);
    epubController.updateTheme(theme: _buildEpubTheme());
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

  /// TZ §12.2 — whether the reader is in manga/webtoon layout.
  ///
  /// [ReaderPageTransition.scroll] is the only mode that puts epub.js into
  /// continuous vertical flow, and vertical flow is how manga is read, so the
  /// two are one setting. The paginated modes keep the novel layout.
  bool get _isMangaLayout => _pageTransition == ReaderPageTransition.scroll;

  /// sakura_epub's `customCss` is a map of **CSS selector → { property: value }**
  /// (its `updateTheme` merges each selector's object into the epub.js theme
  /// rules). The old flat `{ 'font-family': … }` shape was silently ignored
  /// because those keys were treated as selectors with string values.
  ///
  /// Two layouts — novel and manga — picked by [_isMangaLayout]. Because the
  /// layout is derived from the page-transition mode, [setPageTransition] has
  /// to re-push the theme.
  ///
  /// Both layouts deliberately set the *same* properties on the *same*
  /// selectors and differ only in the values. epub.js reuses one `<style>` per
  /// theme and appends to it — Contents.addStylesheetRules calls insertRule at
  /// the end of the sheet and never clears it — so a property the new layout
  /// simply omits keeps the old layout's value instead of being reset. Every
  /// difference below therefore has to be spelled out on both sides.
  Map<String, dynamic> _readerCss(String fontName) {
    final manga = _isMangaLayout;
    return {
      // No padding here: epub.js writes `padding: 20px` directly onto the
      // book's <body> as an inline style when it paginates, and these rules
      // reach the page as a stylesheet, which an inline style outranks — so any
      // padding set here is silently ignored. The page's breathing room comes
      // from insetting the WebView itself (see ReaderScreen._viewerInset).
      'body': {
        'font-family': fontName,
        'line-height': '$_lineSpacing',
      },
      // Manga: fill the column at the panel's own aspect ratio. The height cap
      // is what letterboxes a tall page and opens a band of background under
      // it, which is exactly what breaks the single-strip illusion — hence
      // `none`. A novel keeps the cap so an illustration can't outgrow a page.
      'img': {
        'max-width': '100%',
        'max-height': manga ? 'none' : '96vh',
        'width': manga ? '100%' : 'auto',
        'height': 'auto',
        'display': 'block',
        'margin-left': manga ? '0' : 'auto',
        'margin-right': manga ? '0' : 'auto',
        // Irrelevant once the box matches the intrinsic ratio; set only so the
        // novel layout's `contain` cannot linger in the sheet.
        'object-fit': manga ? 'fill' : 'contain',
      },
      'svg': {
        'max-width': '100%',
        'max-height': manga ? 'none' : '96vh',
        'width': manga ? '100%' : 'auto',
        'display': 'block',
        'margin-left': manga ? '0' : 'auto',
        'margin-right': manga ? '0' : 'auto',
      },
      // Cover pages: a body whose *only* content is one picture — either a
      // bare <img>/<svg> or one wrapped in a single <div> (Calibre emits
      // <body><div><svg><image/></svg></div>). The :only-child chain keeps
      // this from ever matching a text page that happens to contain an
      // illustration. Centring is done with flex rather than by forcing a
      // height, because these covers carry preserveAspectRatio="none" and
      // would stretch if the box's aspect ratio were changed.
      //
      // Neutralised rather than dropped in manga layout: pinning every
      // full-page panel to 100vh would letterbox the whole strip.
      'body:has(> img:only-child), body:has(> svg:only-child), body:has(> div:only-child > img:only-child), body:has(> div:only-child > svg:only-child)': {
        'display': manga ? 'block' : 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        'height': manga ? 'auto' : '100vh',
        'margin': '0',
        'padding': '0',
      },
      // Calibre wraps each panel in its own <p>/<div>, and those wrappers'
      // margins are what show up as seams between panels. Manga-only, and
      // unlike the rules above it has no reset value — a book's own paragraph
      // margins are unknowable, so there is nothing to restore them to. Left
      // out entirely for novels; switching back re-renders the views, which
      // rebuilds the stylesheet from scratch. The :only-child chain keeps this
      // off ordinary text paragraphs.
      if (manga)
        'p:has(> img:only-child), div:has(> img:only-child), p:has(> svg:only-child), div:has(> svg:only-child)': {
          'margin': '0',
          'padding': '0',
        },
    };
  }

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
      if (_currentCfi.isNotEmpty) {
        await prefs.setString('book_${_bookId}_cfi', _currentCfi);
      }
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
    _loadTimeoutTimer?.cancel();
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
    _loadTimeoutTimer?.cancel();
    // Safety net: covers exit paths that don't route through saveAndClose.
    _releaseBrightness();
    super.dispose();
  }
}
