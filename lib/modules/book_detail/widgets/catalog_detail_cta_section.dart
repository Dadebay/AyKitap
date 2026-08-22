import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/book_download_service.dart';
import '../../../core/theme/app_colors.dart';
import 'book_cta_row.dart';

/// The bottom of [CatalogBookDetailScreen]'s content sheet: the optional
/// "remove from purchased" button, the read/buy CTA row, and the "no file
/// for this book" notice.
class CatalogDetailCtaSection extends StatelessWidget {
  final BookDetail book;
  final BookAccess? access;
  final bool canRemoveFromPurchased;
  final bool removingFromPurchased;
  final VoidCallback onRemoveFromPurchased;
  final VoidCallback onRead;
  final VoidCallback onBuy;
  final VoidCallback onCancelDownload;

  const CatalogDetailCtaSection({
    super.key,
    required this.book,
    required this.access,
    required this.canRemoveFromPurchased,
    required this.removingFromPurchased,
    required this.onRemoveFromPurchased,
    required this.onRead,
    required this.onBuy,
    required this.onCancelDownload,
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
        const SizedBox(height: 28),
        BookCtaRow(
          access: access,
          priceManat: book.price,
          // Watched at the point of use, so the subscription can't drift
          // away from the value it feeds: this is what makes a download
          // that's already running when this screen (re)opens — not just
          // one this screen itself started — show its live progress instead
          // of a plain "Oku" button.
          downloadProgress:
              context.watch<BookDownloadService>().progressOf(book.id),
          onRead: onRead,
          onBuy: onBuy,
          onCancelDownload: onCancelDownload,
        ),
        if (book.bookFiles.isEmpty) ...[
          const SizedBox(height: 14),
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
