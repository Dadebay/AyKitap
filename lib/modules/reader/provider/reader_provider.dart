import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/streak_service.dart';

enum ReaderThemeMode { white, sepia, dark, black }

enum ReaderFontFamily { sfPro, newYork, gilroy }

class ReaderProvider extends ChangeNotifier {
  // ── Epub controller (low-level WebView bridge) ──────────────────────────
  final EpubController epubController = EpubController();

  // ── Page state ───────────────────────────────────────────────────────────
  int _currentPage = 0;
  int _totalPages = 0;
  int? _lastLoggedPage;
  double _progress = 0.0;
  String _currentCfi = '';
  String _currentHref = '';
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

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _showControls = false;
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
  ReaderFontFamily _fontFamily = ReaderFontFamily.sfPro;
  double _fontSize = 18.0;
  double _lineSpacing = 1.5;

  ReaderThemeMode get themeMode => _themeMode;
  ReaderFontFamily get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;

  EpubTheme get currentEpubTheme => _buildEpubTheme();

  // ── Book info ─────────────────────────────────────────────────────────────
  int? _bookId;
  Timer? _saveTimer;

  // ── Streak ping (TZ §9.1: "Her 30 sek-de server-e ping iberilýär") ────────
  Timer? _streakPingTimer;
  static const _streakPingInterval = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize({required int bookId}) async {
    _bookId = bookId;
    _isLoading = true;
    notifyListeners();

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
    _currentHref = location.href;
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
    epubController.updateTheme(theme: _buildEpubTheme());
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

  // ─────────────────────────────────────────────────────────────────────────
  // Theme builder
  // ─────────────────────────────────────────────────────────────────────────

  EpubTheme _buildEpubTheme() {
    final fontName = switch (_fontFamily) {
      ReaderFontFamily.sfPro => 'SFPro',
      ReaderFontFamily.newYork => 'NewYork',
      ReaderFontFamily.gilroy => 'Gilroy',
    };

    return switch (_themeMode) {
      ReaderThemeMode.white => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
          foregroundColor: const Color(0xFF000000),
          customCss: {
            'font-family': fontName,
            'line-height': '$_lineSpacing',
            'padding-top': '40px',
            'padding-bottom': '40px',
          },
        ),
      ReaderThemeMode.sepia => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFFf5ebda)),
          foregroundColor: const Color(0xFF3E3329),
          customCss: {
            'font-family': fontName,
            'line-height': '$_lineSpacing',
            'padding-top': '40px',
            'padding-bottom': '40px',
          },
        ),
      ReaderThemeMode.dark => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF1C1C1E)),
          foregroundColor: const Color(0xFFFFFFFF),
          customCss: {
            'font-family': fontName,
            'line-height': '$_lineSpacing',
            'padding-top': '40px',
            'padding-bottom': '40px',
          },
        ),
      ReaderThemeMode.black => EpubTheme.custom(
          backgroundDecoration: const BoxDecoration(color: Color(0xFF000000)),
          foregroundColor: const Color(0xFFABAAB2),
          customCss: {
            'font-family': fontName,
            'line-height': '$_lineSpacing',
            'padding-top': '40px',
            'padding-bottom': '40px',
          },
        ),
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
    await _saveProgress();
    _reset();
  }

  void _reset() {
    _currentPage = 0;
    _totalPages = 0;
    _lastLoggedPage = null;
    _progress = 0.0;
    _isLoading = true;
    _showControls = false;
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
    super.dispose();
  }
}
