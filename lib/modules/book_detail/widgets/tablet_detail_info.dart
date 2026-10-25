import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/theme/app_colors.dart';
import 'catalog_detail_stats.dart';

/// The tablet layout's title block — sits to the right of the large cover,
/// left-aligned, on a translucent panel so it stays legible over the blurred
/// cover backdrop whatever colours that cover has.
class TabletDetailInfo extends StatelessWidget {
  final BookDetail book;
  final VoidCallback onTapAuthor;

  const TabletDetailInfo(
      {super.key, required this.book, required this.onTapAuthor});

  static String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(book.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white)),
        if (book.authors.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTapAuthor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(book.authorNames,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 4),
                HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: AppColors.primary,
                    size: 16),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CatalogDetailMetaStat(
                value: _fmtCount(book.readCount),
                label: BookDetailStrings.statRead,
                onImage: true),
            const CatalogDetailMetaDivider(onImage: true),
            CatalogDetailMetaStat(
                value: _fmtCount(book.soldCount),
                label: BookDetailStrings.statPurchased,
                onImage: true),
            if (book.pageCount != null) ...[
              const CatalogDetailMetaDivider(onImage: true),
              CatalogDetailMetaStat(
                  value: '${book.pageCount}',
                  label: BookDetailStrings.statPages,
                  onImage: true),
            ],
          ],
        ),
        if (book.bookFiles.isNotEmpty ||
            book.age != null ||
            book.year != null) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (book.bookFiles.isNotEmpty)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedFile02,
                    label: book.bookFiles.first.fileFormat.toUpperCase(),
                    onImage: true),
              if (book.age != null)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedShield01,
                    label: '${book.age}+',
                    onImage: true),
              if (book.year != null)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    label: '${book.year}',
                    onImage: true),
            ],
          ),
        ],
      ],
    );
  }
}
