import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import 'book_cover_thumb.dart';

/// One row of a ranked collection's list: rank number, cover, title, author
/// and (when known) the page count.
class RankedListTile extends StatelessWidget {
  final int rank;
  final LibraryBook book;

  /// Tablet sizing: bigger cover and type, and no side inset of its own
  /// because the two-column grid that hosts it already pads the page.
  final bool large;
  const RankedListTile(
      {super.key, required this.rank, required this.book, this.large = false});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    final heroTag = AppHeroTags.catalogBookCover(book.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(large ? 0 : 20, 6, large ? 0 : 20, 6),
      child: PressableScale(
        onTap: () => context.pushHero(CatalogBookDetailScreen(
          bookId: book.id,
          heroTag: heroTag,
          initialCoverUrl: image != null && image.isNotEmpty
              ? ApiConfig.resolveImageUrl(image)
              : null,
        )),
        // No fill — the row sits directly on the page background; only the
        // cover's own shadow (see [BookCoverThumb]) gives it depth.
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                  width: large ? 28 : 22,
                  child: Text('$rank',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: large ? 20 : 16,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              BookCoverThumb(
                  imageUrl: image, heroTag: heroTag, width: large ? 76 : 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name,
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: large ? 17 : 14.5,
                            fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(book.authorNames,
                        style:
                            TextStyle(
                                color: AppColors.grey2,
                                fontSize: large ? 14.5 : 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (book.pageCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                              icon: HugeIcons.strokeRoundedBook02,
                              color: AppColors.grey2,
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                              '${book.pageCount} ${BookDetailStrings.statPages}',
                              style: TextStyle(
                                  color: AppColors.grey2, fontSize: 11.5)),
                        ],
                      ),
                    ],
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
