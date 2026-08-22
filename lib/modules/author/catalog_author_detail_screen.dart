import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/models/author_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/author_api_service.dart';
import '../../core/services/book_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/localization/strings/author_strings.dart';
import '../home/widgets/catalog_book_card.dart';
import 'widgets/catalog_author_header_art.dart';

/// Detail page for a real author (`GET /authors/:id`) — reached by tapping
/// an avatar in one of Home's `type: "author"` collections. Distinct from
/// [AuthorScreen], which still runs on the mock catalogue.
class CatalogAuthorDetailScreen extends StatefulWidget {
  final int authorId;
  const CatalogAuthorDetailScreen({super.key, required this.authorId});

  @override
  State<CatalogAuthorDetailScreen> createState() => _CatalogAuthorDetailScreenState();
}

enum _AuthorBooksSort { name, date }

class _CatalogAuthorDetailScreenState extends State<CatalogAuthorDetailScreen> {
  AuthorDetail? _author;
  List<LibraryBook>? _books;
  bool _loading = true;
  String? _error;
  bool _bioExpanded = false;
  // Client-side only — the author's books are already fetched in full
  // (see `_load`'s `size: 100` default), so re-sorting locally avoids a
  // round-trip the `/books/all` `sort_by`/`sort_order` params would need.
  _AuthorBooksSort? _sort = _AuthorBooksSort.name;

  List<LibraryBook> _sortedBooks(List<LibraryBook> books) {
    if (_sort == null) return books;
    final sorted = List<LibraryBook>.from(books);
    switch (_sort!) {
      case _AuthorBooksSort.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _AuthorBooksSort.date:
        // Newest first; books without a year sink to the bottom.
        sorted.sort((a, b) => (b.year ?? -1).compareTo(a.year ?? -1));
    }
    return sorted;
  }

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
      final author = await AuthorApiService.getAuthorById(widget.authorId);
      if (!mounted) return;
      setState(() {
        _author = author;
        _loading = false;
      });
      // Best-effort: the author's own record above is what this screen
      // needs at minimum, so a books-by-author failure here shouldn't
      // block it — the grid just stays empty instead of an error state.
      try {
        final books = await BookApiService.listBooks(authorId: widget.authorId);
        if (mounted) setState(() => _books = books);
      } on ApiException {
        // ignore
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          _buildBody(),
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 12),
            child: IconCircleButton(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              onTap: () => Navigator.pop(context),
              size: 38,
              iconSize: 18,
              backgroundColor: Colors.black.withValues(alpha: 0.35),
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AuthorStrings.loadError, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: Text(AuthorStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final author = _author!;
    final image = author.image;
    final imageUrl = image != null && image.isNotEmpty ? ApiConfig.resolveImageUrl(image) : null;
    final books = _books ?? const [];
    final sortedBooks = _sortedBooks(books);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Full-bleed, unlike the rest of the content below — matches
        // CatalogBookDetailScreen's hero, which also escapes its content's
        // side padding.
        CatalogAuthorHeaderArt(imageUrl: imageUrl),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Text(author.name, textAlign: TextAlign.center, style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              if (books.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(AuthorStrings.booksCountLabel(books.length), textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              ],
              if (author.bio != null && author.bio!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  author.bio!,
                  maxLines: _bioExpanded ? null : 5,
                  overflow: _bioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.5),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                  child: Text(
                    _bioExpanded ? AuthorStrings.showLess : AuthorStrings.readMore,
                    style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              // `_books` stays null while that fetch is still in flight (or
              // if it failed — see the comment in `_load`), so this only
              // renders once it's actually settled: either the grid, or —
              // genuinely zero books, not "not loaded yet" — the empty
              // state below.
              if (_books != null) ...[
                const SizedBox(height: 24),
                if (books.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(AuthorStrings.allBooks, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      _buildSortButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedBooks.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.50,
                    ),
                    itemBuilder: (context, i) => CatalogBookCard(book: sortedBooks[i], width: double.infinity, coverHeight: 170, margin: EdgeInsets.zero),
                  ),
                ] else
                  _buildNoBooks(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_AuthorBooksSort>(
      // Picking the already-active sort turns it back off (server order)
      // instead of being a no-op.
      onSelected: (value) => setState(() => _sort = _sort == value ? null : value),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _sortMenuItem(_AuthorBooksSort.name, AuthorStrings.sortAZ, HugeIcons.strokeRoundedSortingAZ01),
        _sortMenuItem(_AuthorBooksSort.date, AuthorStrings.sortByDate, HugeIcons.strokeRoundedCalendar03),
      ],
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedSortingAZ01,
          color: _sort != null ? AppColors.primary : AppColors.grey1,
          size: 18,
        ),
      ),
    );
  }

  PopupMenuItem<_AuthorBooksSort> _sortMenuItem(_AuthorBooksSort value, String label, List<List<dynamic>> icon) {
    final selected = _sort == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: selected ? AppColors.primary : AppColors.grey1, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildNoBooks() {
    final isDark = AppTheme.instance.isDark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset(
              isDark ? 'assets/images/author_no_books_dark.webp' : 'assets/images/author_no_books_light.webp',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AuthorStrings.noBooksYetTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          AuthorStrings.noBooksYetSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.4),
        ),
      ],
    );
  }
}
