import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/book_download_service.dart';
import '../../../core/theme/app_colors.dart';
import 'book_cta_row.dart';

/// Secondary actions and notices that remain part of the scrolling content.
class CatalogDetailCtaSection extends StatelessWidget {
  final BookDetail book;
  final bool canRemoveFromPurchased;
  final bool removingFromPurchased;
  final VoidCallback onRemoveFromPurchased;

  const CatalogDetailCtaSection({
    super.key,
    required this.book,
    required this.canRemoveFromPurchased,
    required this.removingFromPurchased,
    required this.onRemoveFromPurchased,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canRemoveFromPurchased) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: removingFromPurchased ? null : onRemoveFromPurchased,
              icon: removingFromPurchased
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.redAccent),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.redAccent,
                      size: 18),
              label: Text(BookDetailStrings.removeFromPurchased),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
        if (book.bookFiles.isEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: AppColors.grey2,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(BookDetailStrings.noFileForBook,
                      style: TextStyle(
                          color: AppColors.grey2,
                          fontSize: 12.5,
                          height: 1.4))),
            ],
          ),
        ],
      ],
    );
  }
}

/// The always-visible read/buy actions at the bottom of the detail screen.
class CatalogDetailBottomCta extends StatelessWidget {
  final BookDetail book;
  final BookAccess? access;
  final VoidCallback onRead;
  final VoidCallback onBuy;
  final VoidCallback onCancelDownload;

  const CatalogDetailBottomCta({
    super.key,
    required this.book,
    required this.access,
    required this.onRead,
    required this.onBuy,
    required this.onCancelDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: BookCtaRow(
          access: access,
          priceManat: book.price,
          // Watch here so an in-flight download keeps updating even though
          // the CTA is no longer part of the scrolling content.
          downloadProgress:
              context.watch<BookDownloadService>().progressOf(book.id),
          onRead: onRead,
          onBuy: onBuy,
          onCancelDownload: onCancelDownload,
        ),
      ),
    );
  }
}
