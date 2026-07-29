import 'package:aykitap/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/book_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/book_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../author/catalog_author_detail_screen.dart';
import 'widgets/catalog_detail_header_art.dart';
import 'widgets/detail_header_controls.dart';
import 'widgets/genre_tag.dart';

/// Detail page for a real catalogue book (`GET /books/:id`) — reachable
/// from [LibraryScreen]'s API-backed tabs, Home's collection sections, and
/// a banner's `book_id`.
///
/// Shows everything the backend sends (cover, authors, genres, stats,
/// description) but has no working "Oka" — `bookFiles[].file_key` is an
/// internal storage path, not something this app has a way to fetch yet.
class CatalogBookDetailScreen extends StatefulWidget {
  final int bookId;
  const CatalogBookDetailScreen({super.key, required this.bookId});

  @override
  State<CatalogBookDetailScreen> createState() => _CatalogBookDetailScreenState();
}

class _CatalogBookDetailScreenState extends State<CatalogBookDetailScreen> {
  BookDetail? _book;
  bool _loading = true;
  String? _error;
  bool _descriptionExpanded = false;
  bool _isFavorite = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await BookApiService.getBookById(widget.bookId);
      if (!mounted) return;
      setState(() {
        _book = book;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toggleFinished() {
    setState(() => _isFinished = !_isFinished);
    context.showAppSnackBar(_isFinished ? BookDetailStrings.finishedAdded : BookDetailStrings.finishedRemoved);
  }

  // Optimistic: the local toggle is the UI's source of truth, the like/unlike
  // call is a best-effort sync — this is a real `LibraryBook.id`, unlike the
  // mock catalogue's ids, so (unlike BookDetailScreen) this one actually
  // persists. See BookApiService's doc comment.
  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    context.showAppSnackBar(_isFavorite ? BookDetailStrings.favoriteAdded : BookDetailStrings.favoriteRemoved);
    final bookId = widget.bookId.toString();
    final future = _isFavorite ? BookApiService.likeBook(bookId) : BookApiService.unlikeBook(bookId);
    future.catchError((_) {});
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
        final file = await DefaultCacheManager().getSingleFile(ApiConfig.resolveImageUrl(image));
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
    final isDark = AppTheme.instance.isDark;

    if (_loading || _error != null) {
      return Stack(
        children: [
          if (_loading)
            Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _load, child: Text(BookDetailStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
          _buildBackButton(context),
        ],
      );
    }
    final book = _book!;
    final image = book.image;
    final imageUrl = image != null && image.isNotEmpty ? ApiConfig.resolveImageUrl(image) : null;
    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, height: _headerHeight, child: CatalogDetailHeaderArt(imageUrl: imageUrl)),
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
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 12),
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
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, -6))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              Text(book.name, textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              if (book.authors.isNotEmpty) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _openAuthor(book.authors.first),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(book.authorNames, style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 3),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MetaStat(value: _fmtCount(book.readCount), label: BookDetailStrings.statRead),
                  const _MetaDivider(),
                  _MetaStat(value: _fmtCount(book.soldCount), label: BookDetailStrings.statPurchased),
                  if (book.pageCount != null) ...[const _MetaDivider(), _MetaStat(value: '${book.pageCount}', label: BookDetailStrings.statPages)],
                ],
              ),
              if (book.genres.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(BookDetailStrings.genres, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: book.genres.map((g) => GenreTag(label: g.name)).toList()),
                ),
              ],
              if (book.description != null && book.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(BookDetailStrings.aboutBook, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                Text(
                  book.description!,
                  maxLines: _descriptionExpanded ? null : 5,
                  overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                    child: Text(
                      _descriptionExpanded ? BookDetailStrings.showLess : BookDetailStrings.readFull,
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: AppColors.grey2, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(BookDetailStrings.readingNotAvailable, style: TextStyle(color: AppColors.grey2, fontSize: 12.5, height: 1.4))),
                  ],
                ),
              ),
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
        Text(value, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
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
    return Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 20), color: AppColors.border);
  }
}
