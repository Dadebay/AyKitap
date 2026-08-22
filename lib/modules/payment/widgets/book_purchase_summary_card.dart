import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// [BookPurchaseScreen]'s book-summary card — cover, title, author, formats.
class BookPurchaseSummaryCard extends StatelessWidget {
  final BookDetail book;
  const BookPurchaseSummaryCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final image = book.image;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 92,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image != null && image.isNotEmpty
                  ? NetworkCoverImage(
                      url: ApiConfig.resolveImageUrl(image),
                      placeholder: (_) => const _CoverPlaceholder())
                  : const _CoverPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.name,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (book.authors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(book.authorNames,
                      style: TextStyle(color: AppColors.grey2, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (book.bookFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    book.bookFiles
                        .map((f) => f.fileFormat.toUpperCase())
                        .toSet()
                        .join(' · '),
                    style: TextStyle(
                        color: AppColors.grey3,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedBook02,
              color: AppColors.grey3,
              size: 20)),
    );
  }
}
