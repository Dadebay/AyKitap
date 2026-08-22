import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/localization/strings/reader_bookmark_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/cbz_page_cache.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/reading_progress_reporter.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/stable_hash.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../utils/cbz_extraction.dart';
import '../utils/cbz_scroll_metrics.dart';
import '../utils/eye_care.dart';
import '../utils/page_note.dart';
import '../utils/reader_brightness_controller.dart';
import '../utils/reader_orientation.dart';
import '../utils/reader_streak_ping.dart';
import '../widgets/cbz_settings_sheet.dart';
import '../widgets/pdf_bookmarks_sheet.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_go_to_page_sheet.dart';
import '../widgets/reader_error_overlay.dart';
import '../widgets/reader_focus_page_indicator.dart';
import '../widgets/reader_loading_overlay.dart';
import '../widgets/reader_top_bar.dart';

part 'cbz_reader_screen_lifecycle.dart';
part 'cbz_reader_screen_actions.dart';
part 'cbz_reader_screen_sheets.dart';
part 'cbz_reader_screen_scroll.dart';
part 'cbz_reader_screen_body.dart';

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
///
/// Zip extraction itself lives in `../utils/cbz_extraction.dart` (it has to
/// run on a background isolate — see that file's doc comments); the rest of
/// this screen is split by responsibility across the `part` files above, the
/// same way [PdfReaderScreen] is.
class CbzReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  /// Stable id used to scope this book's saved page and bookmarks — see
  /// [PdfReaderScreen.bookId] for why this exists instead of just hashing the
  /// path inline.
  final int? bookId;

  /// The real `/books/:id` catalogue id — see [PdfReaderScreen.realBookId] for
  /// why it's separate from [bookId] and what it unlocks (notes reaching the
  /// profile's "Notlar" list). Null for the user's own imported chapters.
  final int? realBookId;

  const CbzReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.bookId,
    this.realBookId,
  });

  @override
  State<CbzReaderScreen> createState() => _CbzReaderScreenState();
}

class _CbzReaderScreenState extends State<CbzReaderScreen>
    with WidgetsBindingObserver {
  // Created synchronously (no `late`) so an early back-press — before the
  // async prefs/extraction work below ever runs — can't dispose() a
  // controller that was never initialized. It starts at page 0 and is
  // corrected to the restored page once extraction resolves the real page
  // count; see _applyRestoredPage.
  final PageController _pageController = PageController();

  /// Drives [CbzViewMode.scroll]'s continuous list. Both controllers exist for
  /// the lifetime of the screen (only one is attached at a time, to whichever
  /// mode is built) so switching modes never disposes a live controller.
  final ScrollController _scrollController = ScrollController();

  List<String> _pagePaths = const [];

  /// width/height per page — see [cbzPageAspectRatios]. Empty until extraction
  /// finishes; [CbzScrollMetrics] substitutes a fallback for any page whose
  /// header couldn't be read.
  List<double> _aspectRatios = const [];

  /// Rebuilt whenever the page list or the viewport width changes, since both
  /// change every page's height.
  CbzScrollMetrics? _metrics;
  double _metricsWidth = 0;
  int _currentPage = 0; // 0-based
  int _initialPage = 0;
  int? _lastLoggedPage;
  bool _isLoading = true;
  String? _error;

  bool _showControls = true;
  double _brightness = 1.0;
  // Blue-light "eye care" wash, shared across every reader via the
  // `reader_eye_care` pref. 0.0 = off.
  double _eyeCare = 0.0;
  bool _darkGutter = true;
  BoxFit _fit = BoxFit.contain;
  CbzViewMode _viewMode = CbzViewMode.scroll;

  Timer? _saveTimer;
  final ReaderStreakPing _streakPing = ReaderStreakPing();
  final ReaderBrightnessController _brightnessController =
      ReaderBrightnessController();

  int get _bookId => widget.bookId ?? stableBookKey(widget.filePath);
  int get _totalPages => _pagePaths.length;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    enableReaderLandscape();
    _bootstrap();
    WidgetsBinding.instance.addObserver(this);
    _streakPing.start();
  }

  /// See [ReaderProvider]'s doc comment on the equivalent override — only
  /// `paused` (genuinely backgrounded) and `resumed` toggle the ping;
  /// `inactive`'s brief, non-backgrounding interruptions are left alone. Body
  /// lives in cbz_reader_screen_lifecycle.dart.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _handleAppLifecycleState(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _scrollController.dispose();
    _saveTimer?.cancel();
    _streakPing.flushResidual();
    _brightnessController.release();
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    restoreAppPortraitLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);

  /// `setState` is `@protected` on [State] — see [PdfReaderScreen]'s
  /// equivalent wrapper for why the `extension`s in the part files above
  /// need this instead of calling `setState(...)` directly.
  void _setState(VoidCallback fn) => setState(fn);
}
