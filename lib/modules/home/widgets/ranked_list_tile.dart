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
  const RankedListTile({super.key, required this.rank, required this.book});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    final heroTag = AppHeroTags.catalogBookCover(book.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
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
                  width: 22,
                  child: Text('$rank',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 10),
              BookCoverThumb(imageUrl: image, heroTag: heroTag),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.name,
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(book.authorNames,
                        style:
                            TextStyle(color: AppColors.grey2, fontSize: 12.5),
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
