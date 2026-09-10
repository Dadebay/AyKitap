import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/layout/window_size_class.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/localization/strings/reader_notes_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/notes_store.dart';
import '../../../core/services/user_notes_api_service.dart';
import '../../../core/theme/highlight_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../profile/widgets/edit_note_sheet.dart';
import '../provider/reader_provider.dart';
import '../utils/eye_care.dart';
import '../utils/pdf_book_opener.dart';
import '../utils/reader_orientation.dart';
import '../utils/reader_tap_gate.dart';
import '../widgets/book_opening_overlay.dart';
import '../widgets/bookmarks_sheet.dart';
import '../widgets/chapter_list_sheet.dart';
import '../widgets/epub_error_view.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/reader_top_bar.dart';
import '../widgets/search_sheet.dart';
import '../widgets/selection_toolbar.dart';
import 'pdf_reader_screen.dart';

part 'reader_view_body.dart';
part 'reader_view_chrome.dart';
part 'reader_view_epub_viewer.dart';
part 'reader_view_notes.dart';
part 'reader_view_sheets.dart';

class ReaderScreen extends StatefulWidget {
  final String bookPath;
  final int bookId;
  final String bookTitle;

  /// Cover artwork (asset path) shown in the chapter-list sheet header. Null
  /// for the user's own imported files, which have no catalogue cover.
  final String? coverUrl;

  /// Total page count from the catalogue metadata, used to render an estimated
  /// "page X of Y" in the chapter-list header (the epub engine only exposes a
  /// 0–1 progress, so the page is derived from it). Null when unknown.
  final int? bookPages;

  /// The catalogue book's `book_{seed}_{index}` id (TZ §12.7). Present only
  /// when the reader was opened for a MockData book — highlights/notes taken
  /// here are linked back to it in the profile's Notlar list. Null for the
  /// user's own imported files, which no catalogue book can regenerate.
  final String? bookRef;

  /// The real `/books/:id` catalogue id, present when this book was opened
  /// from the real backend catalogue (`BookOpenFlow`/`openCatalogBookFile`
  /// pass it through). When set, notes captured here are also persisted via
  /// `POST /users/notes` (see `_addNote`) instead of staying purely local
  /// like the user's own imported files — that backend copy is what makes
  /// them show up in the profile's "Notlar" list ([NotesScreen]), which
  /// reads only from there.
  final int? realBookId;

  /// Set only when [bookPath] is a synthetic EPUB generated from a PDF by
  /// [PdfReflowService] — the original file, so the settings sheet can offer
  /// "view original PDF pages" for a book whose source has a broken
  /// font/text encoding (some words extract as gibberish even though the
  /// page itself renders fine). Null for a real EPUB, where there's no fixed
  /// page view to fall back to.
  final String? originalPdfPath;

  const ReaderScreen({
    super.key,
    required this.bookPath,
    required this.bookId,
    required this.bookTitle,
    this.coverUrl,
    this.bookPages,
    this.bookRef,
    this.realBookId,
    this.originalPdfPath,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  /// Tells a genuine tap (toggle the chrome) apart from a scroll or page
  /// turn. Fed from both Flutter's pointer stream and the WebView's own
  /// touch callbacks — see [ReaderTapGate] for why one source isn't enough.
  final ReaderTapGate _tapGate = ReaderTapGate();

  // Kept separate from provider.isLoading so the overlay can finish its
  // 100% animation and hold briefly instead of vanishing the instant the
  // epub actually becomes ready.
  bool _showLoadingOverlay = true;

  /// Vertical breathing room reserved around the page text.
  ///
  /// It has to be taken out of the *viewer's own box*, not added as CSS
  /// padding: epub.js paginates to fill the WebView's viewport and writes its
  /// own `padding: 20px` straight onto the book's `<body>` as an inline style,
  /// which no rule we inject through the theme can outrank. Shrinking the
  /// viewport is the only lever that epub.js actually lays out against.
  ///
  /// Sized to clear the focus-mode chapter title and page number, which float
  /// over the page while the chrome is hidden and used to land on top of the
  /// text. [SafeArea] handles the notch and gesture bar; this is on top of it.
  static const _viewerInset = EdgeInsets.only(top: 26, bottom: 30);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    enableReaderLandscape();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ReaderProvider>()
          .initialize(bookId: widget.bookId, bookTitle: widget.bookTitle);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registers a MediaQuery dependency (same as MediaQuery.of), so this
    // re-runs on its own whenever the window is resized, rotated, or a
    // fold's posture changes — window resize, rotation, a fold opening or
    // closing. See ReaderProviderLayout.updateWindowSizeClass: it only ever
    // calls into the already-open WebView's rendition, never rebuilds it, so
    // this never disturbs the current reading position.
    context
        .read<ReaderProvider>()
        .updateWindowSizeClass(WindowSizeClass.of(context));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
    restoreAppPortraitLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The reader is a pushed route, so it won't rebuild on a live language
    // switch unless it depends on [AppLocale] — watch it so the bars/labels
    // re-render in the app's current language while a book is open.
    context.watch<AppLocale>();
    return Consumer<ReaderProvider>(
        builder: (context, provider, _) => _buildScaffold(context, provider));
  }

  /// `setState` is `@protected` on [State] — see [PdfReaderScreen]'s
  /// equivalent wrapper for why the `extension`s in the part files above
  /// need this instead of calling `setState(...)` directly.
  void _setState(VoidCallback fn) => setState(fn);
}
