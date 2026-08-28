import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/home_strings.dart';
import '../../../core/models/collection.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/book_cover_hero.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import '../catalog_collection_books_screen.dart';

/// The `card_type: "card_4"` Home treatment, ported from the web client's
/// RankedGridCard. The filled numeral is rendered behind the cover; a second,
/// transparent-fill outline is clipped to the cover bounds above it. The
/// hidden portion therefore continues across the artwork without obscuring
/// any part of the source image.
class CatalogNumberedBookSection extends StatelessWidget {
  const CatalogNumberedBookSection({
    super.key,
    required this.collection,
    this.compact = false,
  });

  final Collection collection;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final books = collection.books;
    if (books.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth =
        compact ? 150.0 : (screenWidth * 0.56).clamp(196.0, 232.0).toDouble();
    final coverHeight = itemWidth * 0.78 * 1.5;
    final listHeight = coverHeight + (compact ? 45 : 54);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card4SectionHeader(
          collection: collection,
          compact: compact,
          onSeeAll: () => context.pushFade(CatalogCollectionBooksScreen(
            title: collection.name,
            books: books,
          )),
        ),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 20),
            itemCount: books.length,
            separatorBuilder: (_, __) => SizedBox(width: compact ? 8 : 12),
            itemBuilder: (_, index) => _NumberedBookCard(
              rank: index + 1,
              heroTag: AppHeroTags.homeCollectionBookCover(
                collection.id,
                books[index].id,
              ),
              book: books[index],
              width: itemWidth,
              compact: compact,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card4SectionHeader extends StatelessWidget {
  const _Card4SectionHeader({
    required this.collection,
    required this.compact,
    required this.onSeeAll,
  });

  final Collection collection;
  final bool compact;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final subtitle = collection.subTitle;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 0 : 20,
        compact ? 8 : 26,
        compact ? 0 : 20,
        compact ? 10 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            collection.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: compact ? 17 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: compact ? 32 : 40,
            height: 3,
            decoration: BoxDecoration(
              gradient: AppGradients.journeyPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle?.isNotEmpty == true
                      ? subtitle!
                      : '${collection.books.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionSubtitle.copyWith(
                    fontSize: compact ? 11.5 : 13,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                  child: Text(
                    HomeStrings.seeAll,
                    style: AppTextStyles.link.copyWith(
                      fontSize: compact ? 12 : 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberedBookCard extends StatelessWidget {
  const _NumberedBookCard({
    required this.rank,
    required this.book,
    required this.heroTag,
    required this.width,
    required this.compact,
  });

  final int rank;
  final LibraryBook book;
  final String heroTag;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final coverLeft = width * 0.22;
    final coverWidth = width - coverLeft;
    final coverHeight = coverWidth * 1.5;
    final numeralInset = compact ? 8.0 : 10.0;
    final numeralColor = AppColors.white;

    final image = book.image;
    final initialCoverUrl = image != null && image.isNotEmpty
        ? ApiConfig.resolveImageUrl(image)
        : null;

    return PressableScale(
      onTap: () => context.pushHero(CatalogBookDetailScreen(
        bookId: book.id,
        heroTag: heroTag,
        initialCoverUrl: initialCoverUrl,
      )),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: coverHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _RankNumeral(
                    rank: rank,
                    height: coverHeight,
                    leftInset: numeralInset,
                    outlined: false,
                    color: numeralColor,
                  ),
                  Positioned(
                    left: coverLeft,
                    child: _BookCover(
                      book: book,
                      heroTag: heroTag,
                      width: coverWidth,
                      height: coverHeight,
                    ),
                  ),
                  // Only the outline returns above the cover: its transparent
                  // center keeps the book art visible while the filled numeral
                  // remains physically behind the cover.
                  Positioned(
                    left: coverLeft,
                    top: 0,
                    width: coverWidth,
                    height: coverHeight,
                    child: ClipRect(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Shift the same numeral back to its original global
                          // position, then reveal only the slice over the cover.
                          _RankNumeral(
                            rank: rank,
                            height: coverHeight,
                            leftInset: numeralInset - coverLeft,
                            outlined: true,
                            color: Colors.white.withValues(alpha: 0.94),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 8 : 11),
            Padding(
              // Text begins on the same vertical guide as the cover rather
              // than under the numeral gutter.
              padding: EdgeInsets.only(left: coverLeft),
              child: SizedBox(
                width: coverWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.authorNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.grey2,
                        fontSize: compact ? 10.5 : 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: compact ? 12 : 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankNumeral extends StatelessWidget {
  const _RankNumeral({
    required this.rank,
    required this.height,
    required this.leftInset,
    required this.outlined,
    required this.color,
  });

  final int rank;
  final double height;
  final double leftInset;
  final bool outlined;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Web uses a 75:100 SVG viewBox for one digit and 150:100 for two. The
    // width reserve below mirrors that geometry while Stack.clipBehavior lets
    // the actual Gilroy glyph breathe beyond it where necessary.
    final width = height * (rank < 10 ? 0.75 : 1.5);
    final strokeWidth = (height * 0.009).clamp(1.8, 2.6).toDouble();
    final numeralStyle = outlined
        ? TextStyle(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = strokeWidth
              ..color = color,
            fontFamily: 'Gilroy',
            fontSize: height * 1.09,
            fontWeight: FontWeight.w500,
            height: 0.92,
            letterSpacing: -height * 0.04,
          )
        : TextStyle(
            color: color,
            fontFamily: 'Gilroy',
            fontSize: height * 1.09,
            fontWeight: FontWeight.w500,
            height: 0.92,
            letterSpacing: -height * 0.04,
          );
    return Positioned(
      left: leftInset,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: width,
          height: height,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '$rank',
              maxLines: 1,
              style: numeralStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({
    required this.book,
    required this.heroTag,
    required this.width,
    required this.height,
  });

  final LibraryBook book;
  final String heroTag;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    return BookCoverHero(
      tag: heroTag,
      width: width,
      height: height,
      style: BookCoverStyle(
        borderRadius: 12,
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: image != null && image.isNotEmpty
          ? NetworkCoverImage(
              url: ApiConfig.resolveImageUrl(image),
              decodeCacheWidth: 650,
              placeholder: (_) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedBook02,
          color: AppColors.grey3,
        ),
      );
}
