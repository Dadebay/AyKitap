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

  const TabletDetailInfo({super.key, required this.book, required this.onTapAuthor});

  static String _fmtCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(book.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
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
                          style: TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CatalogDetailMetaStat(value: _fmtCount(book.readCount), label: BookDetailStrings.statRead),
                const CatalogDetailMetaDivider(),
                CatalogDetailMetaStat(value: _fmtCount(book.soldCount), label: BookDetailStrings.statPurchased),
                if (book.pageCount != null) ...[
                  const CatalogDetailMetaDivider(),
                  CatalogDetailMetaStat(value: '${book.pageCount}', label: BookDetailStrings.statPages),
                ],
              ],
            ),
            if (book.bookFiles.isNotEmpty || book.age != null || book.year != null) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (book.bookFiles.isNotEmpty)
                    CatalogDetailInfoPill(icon: HugeIcons.strokeRoundedFile02, label: book.bookFiles.first.fileFormat.toUpperCase()),
                  if (book.age != null) CatalogDetailInfoPill(icon: HugeIcons.strokeRoundedShield01, label: '${book.age}+'),
                  if (book.year != null) CatalogDetailInfoPill(icon: HugeIcons.strokeRoundedCalendar03, label: '${book.year}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
