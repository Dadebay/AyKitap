import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sakura_epub/sakura_epub.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/layout/window_size_class.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/models/reading_note.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/notes_store.dart';
import '../../../core/services/reading_progress_reporter.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/highlight_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../utils/reader_brightness_controller.dart';
import '../utils/reader_streak_ping.dart';
import 'reader_enums.dart';

export 'reader_enums.dart';

part 'reader_provider_lifecycle.dart';
part 'reader_provider_chapters.dart';
part 'reader_provider_callbacks.dart';
part 'reader_provider_ui_actions.dart';
part 'reader_provider_appearance.dart';
part 'reader_provider_theme_css.dart';
part 'reader_provider_bookmarks.dart';
part 'reader_provider_persistence.dart';
part 'reader_provider_layout.dart';

/// Drives one open EPUB (TZ §12): the WebView bridge in [epubController],
/// reading position/progress, chapters/TOC, highlights, appearance settings
/// and the streak/brightness side effects that go with an open book.
///
/// One [ReaderProvider] instance is created per reader screen (see
/// `docs/provider-inventory.md` — it is *not* a `.instance` singleton), so
/// its state resets naturally when the screen is popped and a fresh one is
/// pushed for the next book.
///
/// The implementation is split by responsibility across the `part` files
/// listed above — chapters/TOC lookup, epub.js callbacks, UI actions,
/// appearance settings, theme/CSS building and progress persistence — each
/// contributing `extension` members on this class so the split is purely
/// mechanical: every method below still resolves and behaves exactly as it
/// did when the whole class lived in one file. Fields stay here because Dart
/// doesn't allow splitting one class's field declarations across files.
class ReaderProvider extends ChangeNotifier with WidgetsBindingObserver {
  // ── Epub controller (low-level WebView bridge) ──────────────────────────
  final EpubController epubController = EpubController();

  // ── Page state (see reader_provider_callbacks.dart) ─────────────────────
  int _currentPage = 0;
  int _totalPages = 0;
  int? _lastLoggedPage;
  double _progress = 0.0;
  String _currentCfi = '';
  bool _isAtLastPage = false;

  // ── Loading state (see reader_provider_lifecycle.dart) ──────────────────
  bool _isLoading = true;
  bool _isProgressSaving = false;
  bool _renditionConfigured = false;
  bool _loadFailed = false;
  Timer? _loadTimeoutTimer;
  static const _loadTimeout = Duration(seconds: 30);

  // ── Chapters (see reader_provider_chapters.dart) ─────────────────────────
  List<EpubChapter> _chapters = [];
  String _currentHref = '';
  String _currentTocHref = '';

  // ── UI state (see reader_provider_ui_actions.dart) ──────────────────────
  bool _showControls = true;
  String _selectedText = '';
  String? _selectedCfi;
  Rect? _selectionRect;

  // ── Theme & font (see reader_provider_appearance.dart) ──────────────────
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
  double _brightness = 1.0;
  double _eyeCare = 0.0;

  // ── Page transition & reading direction (see reader_provider_appearance.dart) ──
  ReaderPageTransition _pageTransition = ReaderPageTransition.scroll;
  bool _leftHandMode = false;

  // ── Two-page spread (see reader_provider_layout.dart) ────────────────────
  WindowWidthClass _windowWidth = WindowWidthClass.compact;
  Rect? _verticalHinge;
  bool _spreadActive = false;

  // ── Book info (see reader_provider_lifecycle.dart / _persistence.dart) ──
  int? _bookId;
  String _bookTitle = '';
  Timer? _saveTimer;
  String _savedCfi = '';
  String? _savedLocationsJson;

  // ── Streak ping & brightness (see reader_provider_lifecycle.dart / _appearance.dart) ──
  final ReaderStreakPing _streakPing = ReaderStreakPing();
  final ReaderBrightnessController _brightnessController =
      ReaderBrightnessController();
  bool _lifecycleObserverAdded = false;

  /// `inactive` is skipped deliberately — it also fires for brief, non-
  /// backgrounding interruptions (a permission dialog, Control Center, an
  /// incoming call banner) that resolve back to `resumed` almost
  /// immediately, and pausing/resuming the ping for those would just be
  /// noise. Only `paused` (genuinely backgrounded) and `resumed` toggle it.
  /// Body lives in reader_provider_lifecycle.dart.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _handleAppLifecycleState(state);

  @override
  void dispose() {
    _disposeCleanup();
    super.dispose();
  }

  /// `notifyListeners` is `@protected` on [ChangeNotifier] — callable from a
  /// subclass, but not from the `extension`s the part files above use to
  /// split this class's methods across several files (an extension isn't
  /// part of the class hierarchy, even in the same library). This thin
  /// wrapper *is* a real instance member of the subclass, so every part file
  /// calls this instead of `notifyListeners()` directly.
  void _notify() => notifyListeners();
}
