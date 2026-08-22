import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/theme/app_colors.dart';
import 'catalog_detail_stats.dart';

/// Title, author link, the read/purchased/pages stat row and the
/// format/age/year info pills — the top of [CatalogBookDetailScreen]'s
/// content sheet, before the genres/description.
class CatalogDetailHeaderInfo extends StatelessWidget {
  final BookDetail book;
  final VoidCallback onTapAuthor;

  const CatalogDetailHeaderInfo(
      {super.key, required this.book, required this.onTapAuthor});

  static String _fmtCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          book.name,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800),
        ),
        if (book.authors.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTapAuthor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(book.authorNames,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 3),
                HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: AppColors.primary,
                    size: 14),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CatalogDetailMetaStat(
                value: _fmtCount(book.readCount),
                label: BookDetailStrings.statRead),
            const CatalogDetailMetaDivider(),
            CatalogDetailMetaStat(
                value: _fmtCount(book.soldCount),
                label: BookDetailStrings.statPurchased),
            if (book.pageCount != null) ...[
              const CatalogDetailMetaDivider(),
              CatalogDetailMetaStat(
                  value: '${book.pageCount}',
                  label: BookDetailStrings.statPages),
            ],
          ],
        ),
        if (book.bookFiles.isNotEmpty ||
            book.age != null ||
            book.year != null) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (book.bookFiles.isNotEmpty)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedFile02,
                    label: book.bookFiles.first.fileFormat.toUpperCase()),
              if (book.age != null)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedShield01,
                    label: '${book.age}+'),
              if (book.year != null)
                CatalogDetailInfoPill(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    label: '${book.year}'),
            ],
          ),
        ],
      ],
    );
  }
}
