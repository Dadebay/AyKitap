import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../home/widgets/catalog_book_card.dart';

/// A "more like this" row under a book's detail sheet — the author's other
/// books, or others sharing its genre.
///
/// Loads on its own rather than as part of the detail screen's own fetch:
/// `GET /books/:id` says nothing about related books, so this is a second
/// request, and it must never delay (or fail) the page the reader actually
/// came for. A failure or an empty result renders nothing at all — a "no
/// related books" placeholder would be noise at the bottom of a page that
/// has already delivered what it promised.
///
/// [fetch] is a callback rather than a genre/author id so the two callers
/// can each pass the query they mean ([BookListApiService.listBooks] with
/// `authorId` or `genreId`) without this widget growing a mode flag.
class DetailRelatedBooks extends StatefulWidget {
  const DetailRelatedBooks({
    super.key,
    required this.title,
    required this.fetch,
    required this.excludeBookId,
    this.heroPrefix = 'related',
  });

  final String title;
  final Future<List<LibraryBook>> Function() fetch;

  /// The book being viewed — it will come back in its own author/genre
  /// query, and offering "you might also like: the book you are reading"
  /// is the one result guaranteed to be useless.
  final int excludeBookId;

  /// Keeps the two rows' Hero tags distinct: the same book can appear in
  /// both ("by this author" and "same genre"), and two live Heroes sharing
  /// a tag throws.
  final String heroPrefix;

  @override
  State<DetailRelatedBooks> createState() => _DetailRelatedBooksState();
}

class _DetailRelatedBooksState extends State<DetailRelatedBooks> {
  List<LibraryBook>? _books;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final books = await widget.fetch();
      if (!mounted) return;
      setState(() => _books = books
          .where((book) => book.id != widget.excludeBookId)
          .take(_maxBooks)
          .toList());
    } catch (_) {
      // Silent: see the class doc — a secondary row is not worth an error
      // state on a page that already loaded.
      if (mounted) setState(() => _books = const []);
    }
  }

  /// Enough to feel like a shelf, few enough that the request stays cheap
  /// and the row doesn't become its own browsing session.
  static const _maxBooks = 12;

  @override
  Widget build(BuildContext context) {
    final books = _books;
    final isTablet = MediaQuery.sizeOf(context).width >= 700;
    // Nothing to show (or the fetch failed): the section simply isn't there.
    if (books != null && books.isEmpty) return const SizedBox.shrink();
    // Still loading: a shimmer row of the same size, so the sheet isn't an
    // empty block while the cards load and nothing jumps when they land.
    if (books == null) return _buildShimmer(isTablet);

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The detail sheet already supplies the horizontal inset, so the
          // header's own default 20px would double it.
          SectionHeader(
            title: widget.title,
            large: isTablet,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          SizedBox(
            height: isTablet ? 248 : 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: books.length,
              itemBuilder: (_, i) => CatalogBookCard(
                book: books[i],
                width: isTablet ? 130 : 100,
                coverHeight: isTablet ? 195 : 155,
                heroTag: AppHeroTags.relatedBookCover(
                    widget.heroPrefix, books[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isTablet) {
    final cardWidth = isTablet ? 130.0 : 100.0;
    final coverHeight = isTablet ? 195.0 : 155.0;
    Widget block(double w, double h, double r) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(r)));
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: block(150, isTablet ? 20 : 16, 6),
            ),
            SizedBox(
              height: isTablet ? 248 : 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: 8,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(cardWidth, coverHeight, 10),
                      const SizedBox(height: 8),
                      block(cardWidth * 0.8, 10, 4),
                      const SizedBox(height: 4),
                      block(cardWidth * 0.6, 9, 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
