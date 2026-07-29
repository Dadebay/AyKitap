import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../book_detail/catalog_book_detail_screen.dart';

/// A cover + title + author cell for a real [LibraryBook] — Home's
/// collection-section counterpart to [BookCard], which renders the mock
/// catalogue's `Book` from a local asset instead of a network image. Tapping
/// opens [CatalogBookDetailScreen], the real-catalogue detail page.
class CatalogBookCard extends StatelessWidget {
  const CatalogBookCard({
    super.key,
    required this.book,
    this.width = 100,
    this.coverHeight = 155,
    this.margin = const EdgeInsets.only(left: 6, right: 10),
  });

  final LibraryBook book;
  final double width;
  final double coverHeight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    final isDark = AppTheme.instance.isDark;
    return GestureDetector(
      onTap: () => context.push(CatalogBookDetailScreen(bookId: book.id)),
      child: Container(
        width: width,
        margin: margin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: coverHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4)),
                  isDark
                      ? BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 0))
                      : BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: image != null && image.isNotEmpty ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(image), placeholder: (_) => _placeholder()) : _placeholder(),
            ),
            const SizedBox(height: 6),
            Text(book.name, style: TextStyle(color: AppColors.grey1, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(book.authorNames, style: TextStyle(color: AppColors.grey2, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 22));
}
