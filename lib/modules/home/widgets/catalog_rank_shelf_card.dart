import 'package:flutter/material.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import '../catalog_collection_books_screen.dart';

/// The `card_type: "card_2"` visual for one [Collection] — same
/// "banner + top-ranked books + see more" shape as the mock catalogue's
/// `RankShelfCard`, adapted for network images/real books. The banner is
/// the top book's own cover since a real collection has no dedicated
/// banner image of its own.
class CatalogRankShelfCard extends StatelessWidget {
  final Collection collection;
  const CatalogRankShelfCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final books = collection.books;
    final top = books.take(4).toList();
    final bannerImage = books.isNotEmpty ? books.first.image : null;
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
                  bannerImage != null && bannerImage.isNotEmpty
                      ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(bannerImage), placeholder: (_) => Container(color: AppColors.surface))
                      : Container(color: AppColors.surface),
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
                        Text(collection.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        if (collection.subTitle != null && collection.subTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(collection.subTitle!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
                        ],
                      ],
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
                for (int i = 0; i < top.length; i++) ...[
                  _RankedBookTile(rank: i + 1, book: top[i]),
                  if (i != top.length - 1) const SizedBox(height: 12),
                ],
                if (books.length > top.length)
                  Container(
                    width: double.infinity,
                    height: 46,
                    margin: const EdgeInsets.only(top: 14),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.push(CatalogCollectionBooksScreen(title: collection.name, books: books, ranked: true)),
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
  final LibraryBook book;
  const _RankedBookTile({required this.rank, required this.book});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    return GestureDetector(
      onTap: () => context.push(CatalogBookDetailScreen(bookId: book.id)),
      child: Row(
        children: [
          SizedBox(width: 20, child: Text('$rank', style: TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            height: 56,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
              child: image != null && image.isNotEmpty ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(image), placeholder: (_) => const SizedBox.shrink()) : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.name, style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(book.authorNames, style: TextStyle(color: AppColors.grey2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
