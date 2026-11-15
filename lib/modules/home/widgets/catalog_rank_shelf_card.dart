import 'package:flutter/material.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/book_cover_hero.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import '../catalog_collection_books_screen.dart';

/// The `card_type: "card_2"` visual for one [Collection] — same
/// "banner + top-ranked books + see more" shape as the mock catalogue's
/// `RankShelfCard`, adapted for network images/real books. The banner is
/// [Collection.image] — the collection's own banner, uploaded for exactly
/// this card — falling back to the top book's cover only for the rare
/// collection with none set.
class CatalogRankShelfCard extends StatelessWidget {
  final Collection collection;

  /// True when the caller has already given this card a fixed height to
  /// fill (the genre-shelf row, sized to its tallest sibling — see
  /// [_buildGenreShelfRow]'s `rowHeight`) — pins the "see more" button to
  /// the card's bottom edge instead of leaving it stranded under the last
  /// tile with a bare gap underneath whenever the shelf has few books.
  /// False (the default, standalone Home placement) sizes the card to its
  /// own content instead, which an [Expanded] would only be able to do if
  /// wrapped in a bounded height itself — this flag keeps that requirement
  /// opt-in rather than forcing every call site to supply one.
  final bool fillHeight;

  const CatalogRankShelfCard({
    super.key,
    required this.collection,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final books = collection.books;
    final top = books.take(4).toList();
    final ownImage = collection.image;
    final bannerImage = (ownImage != null && ownImage.isNotEmpty)
        ? ownImage
        : (books.isNotEmpty ? books.first.image : null);
    return DecoratedBox(
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: isTablet ? 128 : 84,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  bannerImage != null && bannerImage.isNotEmpty
                      ? NetworkCoverImage(
                          alignment: Alignment.bottomCenter,
                          url: ApiConfig.resolveImageUrl(bannerImage),
                          placeholder: (_) =>
                              Container(color: AppColors.surface),
                        )
                      : Container(color: AppColors.surface),
                  // Scrim so the white text stays legible over the photo.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.15)
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // `right` matters as much as `left` here: without it the
                  // title is laid out unbounded and a long collection name
                  // ("New York Times iň köp satylanlary") simply ran off the
                  // card and was cut by the ClipRRect above. Bounded, it
                  // wraps to a second line instead — 2 lines of 18px plus a
                  // single subtitle line still sit inside this 84px banner.
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 26 : 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (collection.subTitle != null &&
                            collection.subTitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            collection.subTitle!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isTablet ? 18 : 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            fit: fillHeight ? FlexFit.tight : FlexFit.loose,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isTablet ? 18 : 12, 16, isTablet ? 18 : 12, isTablet ? 22 : 16),
              child: Column(
                children: [
                  for (int i = 0; i < top.length; i++) ...[
                    _RankedBookTile(
                        rank: i + 1,
                        book: top[i],
                        collectionId: collection.id,
                        large: isTablet),
                    if (i != top.length - 1) SizedBox(height: isTablet ? 18 : 12),
                  ],
                  // Fills whatever slack space is left when the card is
                  // stretched to match a taller sibling in its shelf row
                  // (see [_buildGenreShelfTile]'s `rowHeight`) — without it
                  // a shelf with few books left the button stranded right
                  // under the last tile instead of pinned to the card's
                  // bottom edge like every other row. A no-op [SizedBox]
                  // outside that context: [Spacer] needs the [Flexible]
                  // above it to actually be bounded, which only
                  // [fillHeight]'s [FlexFit.tight] guarantees.
                  if (fillHeight) const Spacer(),
                  if (books.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: isTablet ? 58 : 46,
                      margin: const EdgeInsets.only(top: 14),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.pushFade(
                            CatalogCollectionBooksScreen(
                                title: collection.name,
                                books: books,
                                ranked: true,
                                bannerImage: bannerImage)),
                        child: Text(HomeStrings.seeMore,
                            style: TextStyle(
                                color: AppColors.grey1,
                                fontSize: isTablet ? 15.5 : 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
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
  final int collectionId;
  final bool large;
  const _RankedBookTile(
      {required this.rank,
      required this.book,
      required this.collectionId,
      required this.large});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    final heroTag = AppHeroTags.homeCollectionBookCover(collectionId, book.id);
    return PressableScale(
      onTap: () => context.pushHero(CatalogBookDetailScreen(
        bookId: book.id,
        heroTag: heroTag,
        initialCoverUrl: image != null && image.isNotEmpty
            ? ApiConfig.resolveImageUrl(image)
            : null,
      )),
      child: Row(
        children: [
          SizedBox(
              width: large ? 28 : 20,
              child: Text('$rank',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: large ? 22 : 15,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          SizedBox(
            width: large ? 68 : 40,
            height: large ? 98 : 56,
            child: BookCoverHero(
              tag: heroTag,
              style: const BookCoverStyle(borderRadius: 6),
              child: image != null && image.isNotEmpty
                  ? NetworkCoverImage(
                      url: ApiConfig.resolveImageUrl(image),
                      placeholder: (_) => const SizedBox.shrink())
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.name,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: large ? 18 : 13.5,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(book.authorNames,
                    style: TextStyle(
                        color: AppColors.grey2, fontSize: large ? 15.5 : 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
