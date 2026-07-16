import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../book_detail/book_detail_screen.dart';
import '../../popular/collection_books_screen.dart';

/// One "İlk 100"-style shelf: a banner photo, a tag/subtitle, and its
/// top-ranked books, with a "see more" button to the full ranked list.
class RankShelf {
  final String tag;
  final String subtitle;
  final String bannerImage;
  final List<Book> books;
  final List<Book> allBooks;
  const RankShelf({required this.tag, required this.subtitle, required this.bannerImage, required this.books, required this.allBooks});
}

class RankShelfCard extends StatelessWidget {
  final RankShelf shelf;
  const RankShelfCard({super.key, required this.shelf});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 84,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(shelf.bannerImage, fit: BoxFit.cover),
                  // Scrim so the white text stays legible over the photo.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.15)],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shelf.tag, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(shelf.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                      child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBookmark02, color: Colors.white, size: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Column(
              children: [
                for (int i = 0; i < shelf.books.length; i++) ...[
                  _RankedBookTile(rank: i + 1, book: shelf.books[i]),
                  if (i != shelf.books.length - 1) const SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  height: 46,
                  margin: const EdgeInsets.only(top: 14),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => context.push(CollectionBooksScreen(title: shelf.tag, books: shelf.allBooks)),
                    child: Text(HomeStrings.seeMore, style: TextStyle(color: AppColors.grey1, fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedBookTile extends StatelessWidget {
  final int rank;
  final Book book;
  const _RankedBookTile({required this.rank, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(BookDetailScreen(book: book)),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$rank', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            height: 56,
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(book.coverImage, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
