import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/strings/reader_bookmark_strings.dart';
import '../../../core/localization/strings/reader_pdf_strings.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/services/bookmarks_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/reading_progress_reporter.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/utils/stable_hash.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../utils/eye_care.dart';
import '../utils/page_note.dart';
import '../utils/pdf_book_opener.dart';
import '../utils/reader_brightness_controller.dart';
import '../utils/reader_orientation.dart';
import '../utils/reader_streak_ping.dart';
import '../widgets/pdf_bookmarks_sheet.dart';
import '../widgets/pdf_bottom_bar.dart';
import '../widgets/pdf_go_to_page_sheet.dart';
import '../widgets/pdf_margin_crop_box.dart';
import '../widgets/pdf_night_mode_filter.dart';
import '../widgets/pdf_settings_sheet.dart';
import '../widgets/reader_error_overlay.dart';
import '../widgets/reader_focus_page_indicator.dart';
import '../widgets/reader_loading_overlay.dart';
import '../widgets/reader_top_bar.dart';

part 'pdf_reader_screen_lifecycle.dart';
part 'pdf_reader_screen_actions.dart';
part 'pdf_reader_screen_sheets.dart';
part 'pdf_reader_screen_layout.dart';
part 'pdf_reader_screen_page_layer.dart';
part 'pdf_reader_screen_body.dart';

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
///
/// The implementation is split by responsibility across the `part` files
/// listed above (lifecycle/restore, settings/progress/bookmark actions,
/// sheet flows and the widget tree) the same way [ReaderProvider] is —
/// `extension`s on the private State class so the split doesn't change this
/// screen's behaviour, only where each method lives.
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
  /// Deliberately separate from [bookId]: that one falls back to a hashed
  /// file path for an import, and a hash is not an id the backend would accept.
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

class _PdfReaderScreenState extends State<PdfReaderScreen>
    with WidgetsBindingObserver {
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

  /// How much of the page's blank print margin to trim — a 0..1 slider
  /// position, not the fraction itself, so the settings sheet can reuse
  /// [ReaderSliderRow] unchanged the way brightness and eye care do.
  /// [_marginCropFraction] is what [PdfMarginCropBox] actually crops by.
  double _marginCrop = 0.0;
  double get _marginCropFraction => _marginCrop * PdfMarginCropBox.maxFraction;

  // Tap vs. scroll discrimination for the focus-mode toggle.
  Offset? _touchStart;
  DateTime? _touchStartAt;

  Timer? _saveTimer;
  final ReaderStreakPing _streakPing = ReaderStreakPing();
  final ReaderBrightnessController _brightnessController =
      ReaderBrightnessController();

  int get _bookId => widget.bookId ?? stableBookKey(widget.filePath);

  @override
  void initState() {
    super.initState();
    // Temporary diagnostic — see PdfOpeningScreen._resolve's comment. If
    // PdfOpeningScreen's own logs finished cleanly but the app still goes
    // down right around here, the crash is in PdfViewer's (pdfrx) own
    // PDFium mount rather than the classification pass above it.
    log('🔍 [PdfReader] initState bookId=$_bookId path=${widget.filePath} '
        'imageOnly=${widget.imageOnly}');
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    enableReaderLandscape();
    _restoreState();
    WidgetsBinding.instance.addObserver(this);
    _streakPing.start();
  }

  /// See [ReaderProvider]'s doc comment on the equivalent override — only
  /// `paused` (genuinely backgrounded) and `resumed` toggle the ping;
  /// `inactive`'s brief, non-backgrounding interruptions are left alone. Body
  /// lives in pdf_reader_screen_lifecycle.dart.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _handleAppLifecycleState(state);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  /// `setState` is `@protected` on [State] — callable from a subclass, but
  /// not from the `extension`s the part files above use to split this
  /// class's methods across several files. This thin wrapper *is* a real
  /// instance member of the subclass, so every part file calls this instead
  /// of `setState(...)` directly.
  void _setState(VoidCallback fn) => setState(fn);
}
