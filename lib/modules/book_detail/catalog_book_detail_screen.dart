import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/models/book_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_hero_tags.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_api_service.dart';
import '../../core/services/book_list_api_service.dart';
import '../../core/services/book_download_service.dart';
import '../../core/services/downloaded_files_store.dart';
import '../../core/services/favorites_sync_service.dart';
import '../../core/services/finished_books_sync_service.dart';
import '../../core/services/last_read_book_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/network_error_state.dart';
import '../author/catalog_author_detail_screen.dart';
import '../home/widgets/stagger_fade_in.dart';
import '../reader/utils/catalog_book_opener.dart';
import 'book_open_flow.dart';
import 'catalog_genre_books_screen.dart';
import 'widgets/catalog_detail_cta_section.dart';
import 'widgets/catalog_detail_description.dart';
import 'widgets/catalog_detail_header_art.dart';
import 'widgets/catalog_detail_header_info.dart';
import 'widgets/detail_header_controls.dart';

part 'catalog_book_detail_actions.dart';
part 'catalog_book_detail_body.dart';

/// Detail page for a real catalogue book (`GET /books/:id`) — reachable
/// from [LibraryScreen]'s API-backed tabs, Home's collection sections, and
/// a banner's `book_id`.
///
/// Shows everything the backend sends (cover, authors, genres, stats,
/// description) plus the "Oku / Satyn al" row: `bookFiles[].file_key` is
/// resolved into a presigned download link ([BookFileApiService]), the file
/// is stored app-privately ([BookDownloadService]) and opened in the
/// matching reader — all of it gated by [BookAccessService] and driven by
/// [BookOpenFlow].
///
/// Split by responsibility across the `part` files above — data loading and
/// access resolution stay here since they're this screen's core lifecycle;
/// the CTA/favorite/share/purchase actions and the content-sheet widget
/// tree are `extension`s on the private State class, the same way the
/// reader screens are.
class CatalogBookDetailScreen extends StatefulWidget {
  final int bookId;
  final bool canRemoveFromPurchased;
  final String? heroTag;
  final String? initialCoverUrl;

  /// Present only for a locally cached "Okuduklarım" book. If the detail
  /// request cannot reach the backend, this allows a downloaded file to open
  /// instead of leaving the reader on an unusable error page.
  final LibraryBook? offlineBook;

  const CatalogBookDetailScreen({
    super.key,
    required this.bookId,
    this.canRemoveFromPurchased = false,
    this.offlineBook,
    this.heroTag,
    this.initialCoverUrl,
  });

  @override
  State<CatalogBookDetailScreen> createState() =>
      _CatalogBookDetailScreenState();
}

class _CatalogBookDetailScreenState extends State<CatalogBookDetailScreen> {
  BookDetail? _book;
  bool _loading = true;
  String? _error;
  bool _descriptionExpanded = false;
  bool _isFavorite = false;
  bool _isFinished = false;
  bool _removingFromPurchased = false;

  /// Null until [_resolveAccess] has run once — the CTA row shows disabled
  /// buttons rather than guessing.
  BookAccess? _access;

  // The blurred cover sits pinned behind the scrolling sheet, which starts
  // a little shy of the header's bottom edge so it can be dragged up over
  // the cover.
  static const _headerHeight = 400.0;
  static const _sheetOverlap = 30.0;

  String get _heroTag =>
      widget.heroTag ?? AppHeroTags.catalogBookCover(widget.bookId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Re-reads the access verdict for the loaded book. Called after the
  /// detail loads and after anything that can change it (login, purchase,
  /// balance top-up).
  Future<void> _resolveAccess() async {
    final book = _book;
    if (book == null) return;
    final access = await BookAccessService.instance.resolve(book);
    if (!mounted) return;
    setState(() => _access = access);
  }

  BookOpenFlow _flow(BookDetail book) => BookOpenFlow(
        context: context,
        book: book,
        heroTag: _heroTag,
        onAccessChanged: _resolveAccess,
      );

  Future<void> _waitForRouteTransition() async {
    // Both call sites in [_load] await a network call first — the screen can
    // be gone by the time that resolves (user backed out while it was slow,
    // e.g. over a flaky VPN), and `context` throws once the State is
    // unmounted.
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) return;

    final completer = Completer<void>();
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) completer.complete();
    }

    animation.addStatusListener(listener);
    await completer.future;
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await BookListApiService.listBooks(wantsTo: true);
      if (!mounted) return;
      final isFavorite =
          favorites.any((favorite) => favorite.id == widget.bookId);
      if (isFavorite != _isFavorite) {
        setState(() => _isFavorite = isFavorite);
      }
    } on ApiException {
      // Secondary state must never delay or replace the usable detail page.
    }
  }

  Future<void> _refreshAccess() async {
    await _resolveAccess();
    await BookAccessService.instance.refreshPurchased();
    await _resolveAccess();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await BookApiService.getBookById(widget.bookId);
      // Keep the loading header stable for the complete Hero flight. A fast
      // response used to replace it with the full detail tree mid-flight,
      // forcing layout and paint work into the transition frames.
      await _waitForRouteTransition();
      if (!mounted) return;
      setState(() {
        _book = book;
        _isFinished = (book.progress ?? 0) >= 100;
        _loading = false;
      });
      // Reaching this screen at all is the user having selected a book —
      // whichever shelf, grid or deep link they tapped it from. Fired here,
      // once per successful load, instead of at every tap site upstream.
      unawaited(AnalyticsService.instance
          .logSelectBook(id: '${widget.bookId}', title: book.name));
      // These secondary states update independently after useful content is
      // visible; neither belongs on the route-transition critical path.
      unawaited(_loadFavoriteStatus());
      unawaited(_refreshAccess());
    } on ApiException catch (e) {
      await _waitForRouteTransition();
      if (!mounted) return;
      final offlineBook = widget.offlineBook;
      if (offlineBook != null && await _openOfflineCopy(offlineBook)) return;
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<bool> _openOfflineCopy(LibraryBook book) async {
    await DownloadedFilesStore.instance.load();
    await BookAccessService.instance.load();
    final entry = DownloadedFilesStore.instance.best(book.id);
    if (entry == null || !BookAccessService.instance.canRead(book.id)) {
      return false;
    }
    await LastReadBookStore.instance.recordOpened(
      book: book,
      path: entry.path,
      format: entry.format,
    );
    if (!mounted) return false;
    openCatalogBookFile(
      context,
      path: entry.path,
      format: entry.format,
      bookId: book.id,
      title: book.name,
      pageCount: book.pageCount,
      coverUrl: book.image == null || book.image!.isEmpty
          ? null
          : ApiConfig.resolveImageUrl(book.image!),
      heroTag: _heroTag,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _buildBody(),
    );
  }

  /// `setState` is `@protected` on [State] — see [PdfReaderScreen]'s
  /// equivalent wrapper for why the `extension`s in the part files above
  /// need this instead of calling `setState(...)` directly.
  void _setState(VoidCallback fn) => setState(fn);
}
