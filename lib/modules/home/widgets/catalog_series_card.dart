import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/localization/strings/series_strings.dart';
import '../../../core/models/collection.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../catalog_collection_books_screen.dart';

/// The `card_type: "card_3"` visual for one [Collection] — same big
/// image-card-with-frosted-title-panel shape as the mock catalogue's
/// `SeriesCard`. The cover is [Collection.image] — the collection's own
/// uploaded cover — falling back to the first book's own cover only when
/// the collection has none set.
class CatalogSeriesCard extends StatelessWidget {
  final Collection collection;
  const CatalogSeriesCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final ownImage = collection.image;
    final coverImage = (ownImage != null && ownImage.isNotEmpty)
        ? ownImage
        : (collection.books.isNotEmpty ? collection.books.first.image : null);
    return PressableScale(
      onTap: () => context.pushFade(CatalogCollectionBooksScreen(
          title: collection.name, books: collection.books)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            coverImage != null && coverImage.isNotEmpty
                ? NetworkCoverImage(
                    url: ApiConfig.resolveImageUrl(coverImage),
                    placeholder: (_) => Container(color: AppColors.card))
                : Container(color: AppColors.card),
            // Frosted glass strip pinned to the bottom edge — the art above
            // it stays untouched and sharp, only the text panel itself is
            // blurred and tinted so the title/count stay legible.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    // No fixed height — a 2-line-wrapped title (common once
                    // this card gets squeezed into a narrower horizontal
                    // row) needs more room than a name that fits on one
                    // line, so the panel has to size to its own content
                    // instead of a constant that only fit the common case.
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    color: Colors.black.withValues(alpha: 0.32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collection.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          SeriesStrings.bookCount(collection.books.length),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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
