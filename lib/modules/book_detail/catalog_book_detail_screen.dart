import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/models/book_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_api_service.dart';
import '../../core/services/favorites_sync_service.dart';
import '../../core/services/finished_books_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/network_error_state.dart';
import '../author/catalog_author_detail_screen.dart';
import 'book_open_flow.dart';
import 'catalog_genre_books_screen.dart';
import 'widgets/book_cta_row.dart';
import 'widgets/catalog_detail_header_art.dart';
import 'widgets/detail_header_controls.dart';
import 'widgets/genre_tag.dart';

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
class CatalogBookDetailScreen extends StatefulWidget {
  final int bookId;
  final bool canRemoveFromPurchased;

  const CatalogBookDetailScreen({
    super.key,
    required this.bookId,
    this.canRemoveFromPurchased = false,
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
  double? _downloadProgress;
  CancelToken? _downloadCancelToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // A download outliving this screen would report progress into a dead
    // State and finish into a reader that can no longer be pushed.
    _downloadCancelToken?.cancel();
    super.dispose();
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
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
        onCancelToken: (token) => _downloadCancelToken = token,
        onAccessChanged: _resolveAccess,
      );

  Future<void> _onRead() async {
    final book = _book;
    if (book == null) return;
    await _flow(book).read();
    await _resolveAccess();
  }

  Future<void> _onBuy() async {
    final book = _book;
    if (book == null) return;
    final bought = await _flow(book).buy();
    await _resolveAccess();
    // Buying is nearly always followed by wanting to read it — carry
    // straight on into the download instead of making the user tap "Oku".
    if (bought && mounted) await _flow(book).read();
  }

  void _cancelDownload() {
    _downloadCancelToken?.cancel();
    _downloadCancelToken = null;
    if (mounted) setState(() => _downloadProgress = null);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await BookApiService.getBookById(widget.bookId);
      // `GET /books/:id` doesn't include a per-user favorite flag. The
      // user's `wants_to` list is the backend source of truth for the heart
      // state when this detail screen is opened again.
      var isFavorite = false;
      try {
        final favoriteBooks = await BookApiService.listBooks(wantsTo: true);
        isFavorite =
            favoriteBooks.any((favorite) => favorite.id == widget.bookId);
      } on ApiException {
        // The book detail remains useful if this secondary status lookup
        // fails; leave the heart in its default, unfilled state.
      }
      if (!mounted) return;
      setState(() {
        _book = book;
        _isFavorite = isFavorite;
        _isFinished = (book.progress ?? 0) >= 100;
        _loading = false;
      });
      // Cheap and cache-first, so the CTA has a verdict almost immediately;
      // the purchased list is re-synced in the background in case it
      // changed on another device.
      await _resolveAccess();
      await BookAccessService.instance.refreshPurchased();
      await _resolveAccess();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // Only the "mark as finished" direction syncs — un-marking has no
  // well-defined progress to report back (the user's real reading
  // position isn't tracked here), so that half just stays a local toggle.
  void _toggleFinished() {
    setState(() => _isFinished = !_isFinished);
    context.showAppSnackBar(_isFinished
        ? BookDetailStrings.finishedAdded
        : BookDetailStrings.finishedRemoved);
    if (_isFinished) {
      BookApiService.updateProgress(widget.bookId, progress: 100)
          .then((_) => FinishedBooksSyncService.instance.notifyChanged())
          .catchError((_) {});
    }
  }

  // Optimistic: the local toggle is the UI's source of truth, the like/unlike
  // call is a best-effort sync — this is a real `LibraryBook.id`, unlike the
  // mock catalogue's ids, so (unlike BookDetailScreen) this one actually
  // persists. See BookApiService's doc comment.
  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    context.showAppSnackBar(_isFavorite
        ? BookDetailStrings.favoriteAdded
        : BookDetailStrings.favoriteRemoved);
    final bookId = widget.bookId.toString();
    final future = _isFavorite
        ? BookApiService.likeBook(bookId)
        : BookApiService.unlikeBook(bookId);
    // Only notifies once the like/unlike has actually landed server-side —
    // firing it immediately (before this even started) let LibraryScreen's
    // favorites tab re-fetch `wants_to=true` before the DELETE had taken
    // effect, so it came back still containing the book that was just
    // unliked and then never refreshed again. Silent on failure: nothing
    // changed server-side, so there's nothing for the list to pick up.
    future
        .then((_) => FavoritesSyncService.instance.notifyChanged())
        .catchError((_) {});
  }

  static String _fmtCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Future<void> _onShare(BookDetail book) async {
    final text = BookDetailStrings.shareText(
      book.name,
      book.authorNames,
      genres: book.genres.map((g) => g.name).toList(),
      pages: book.pageCount,
      synopsis: book.description,
    );
    final image = book.image;
    if (image != null && image.isNotEmpty) {
      // Reuses NetworkCoverImage's cache — the cover shown on this very
      // page is very likely cached on disk already, so this is usually
      // instant rather than a fresh download.
      try {
        final file = await DefaultCacheManager()
            .getSingleFile(ApiConfig.resolveImageUrl(image));
        await Share.shareXFiles([XFile(file.path)], text: text);
        return;
      } catch (_) {
        // Falls through to text-only share below.
      }
    }
    await Share.share(text);
  }

  void _openAuthor(LibraryBookAuthor author) {
    context.push(CatalogAuthorDetailScreen(authorId: author.id));
  }

  void _openGenre(BookDetailGenre genre) {
    context.push(
        CatalogGenreBooksScreen(genreId: genre.id, genreName: genre.name));
  }

  Future<void> _removeFromPurchased(BookDetail book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          BookDetailStrings.removeFromPurchased,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800),
        ),
        content: Text(
          BookDetailStrings.removePurchasedConfirm(book.name),
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BookDetailStrings.cancel,
                style: TextStyle(color: AppColors.grey2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(BookDetailStrings.remove,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingFromPurchased = true);
    try {
      await BookApiService.removeBoughtBook(book.id);
      if (!mounted) return;
      context
          .showAppSnackBar(BookDetailStrings.removedFromPurchased(book.name));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _removingFromPurchased = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  // The blurred cover sits pinned behind the scrolling sheet, which starts
  // a little shy of the header's bottom edge so it can be dragged up over
  // the cover.
  static const _headerHeight = 400.0;
  static const _sheetOverlap = 30.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _error != null) {
      return Stack(
        children: [
          if (_loading)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            NetworkErrorState(onRetry: _load),
          _buildBackButton(context),
        ],
      );
    }
    final book = _book!;
    final image = book.image;
    final imageUrl = image != null && image.isNotEmpty
        ? ApiConfig.resolveImageUrl(image)
        : null;
    return Stack(
      children: [
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: CatalogDetailHeaderArt(imageUrl: imageUrl)),
        ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: _headerHeight - _sheetOverlap),
            _buildContentSheet(book),
          ],
        ),
        DetailHeaderControls(
          isFinished: _isFinished,
          isFavorite: _isFavorite,
          onBack: () => Navigator.pop(context),
          onToggleFinished: _toggleFinished,
          onToggleFavorite: _toggleFavorite,
          onShare: () => _onShare(book),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8, left: 12),
      child: IconCircleButton(
        icon: HugeIcons.strokeRoundedArrowLeft01,
        onTap: () => Navigator.pop(context),
        size: 38,
        iconSize: 18,
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        iconColor: Colors.white,
      ),
    );
  }

  Widget _buildContentSheet(BookDetail book) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(38), topRight: Radius.circular(38)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(38), topRight: Radius.circular(38)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              Text(book.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              if (book.year != null) ...[
                const SizedBox(height: 4),
                Text(BookDetailStrings.publishedYearLabel(book.year!),
                    style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
              ],
              if (book.authors.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openAuthor(book.authors.first),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(book.authorNames,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 3),
                      HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: AppColors.primary,
                          size: 14),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MetaStat(
                      value: _fmtCount(book.readCount),
                      label: BookDetailStrings.statRead),
                  const _MetaDivider(),
                  _MetaStat(
                      value: _fmtCount(book.soldCount),
                      label: BookDetailStrings.statPurchased),
                  if (book.pageCount != null) ...[
                    const _MetaDivider(),
                    _MetaStat(
                        value: '${book.pageCount}',
                        label: BookDetailStrings.statPages)
                  ],
                ],
              ),
              if (book.genres.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(BookDetailStrings.genres,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: book.genres
                          .map((g) => GenreTag(
                              label: g.name, onTap: () => _openGenre(g)))
                          .toList()),
                ),
              ],
              if (book.description != null && book.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(BookDetailStrings.aboutBook,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                Text(
                  book.description!,
                  maxLines: _descriptionExpanded ? null : 5,
                  overflow: _descriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.grey1, fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded),
                    child: Text(
                      _descriptionExpanded
                          ? BookDetailStrings.showLess
                          : BookDetailStrings.readFull,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (widget.canRemoveFromPurchased) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _removingFromPurchased
                        ? null
                        : () => _removeFromPurchased(book),
                    icon: _removingFromPurchased
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.redAccent))
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            color: Colors.redAccent,
                            size: 18),
                    label: Text(BookDetailStrings.removeFromPurchased),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              BookCtaRow(
                access: _access,
                priceManat: book.price,
                downloadProgress: _downloadProgress,
                onRead: _onRead,
                onBuy: _onBuy,
                onCancelDownload: _cancelDownload,
              ),
              if (book.bookFiles.isEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        color: AppColors.grey2,
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(BookDetailStrings.noFileForBook,
                            style: TextStyle(
                                color: AppColors.grey2,
                                fontSize: 12.5,
                                height: 1.4))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String value;
  final String label;
  const _MetaStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.border);
  }
}
