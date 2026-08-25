import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/theme/app_colors.dart';

/// The book detail page's action row: `[ Oku ] [ Satyn al · 10 M ]`.
///
/// Purely presentational — [BookAccess] is resolved by [BookAccessService]
/// and handed in, so this widget never decides who may read what. While a
/// download is running the "Oku" button becomes a cancellable percentage
/// readout instead of pushing a second one.
class BookCtaRow extends StatelessWidget {
  /// Null while the verdict is still being resolved — both buttons show
  /// disabled rather than flashing the wrong label for a frame.
  final BookAccess? access;

  /// The book's price in manat; 0/null means free, so no buy button.
  final int? priceManat;

  /// 0–1 while downloading, null otherwise.
  final double? downloadProgress;

  final VoidCallback onRead;
  final VoidCallback onBuy;
  final VoidCallback onCancelDownload;

  const BookCtaRow({
    super.key,
    required this.access,
    required this.priceManat,
    required this.onRead,
    required this.onBuy,
    required this.onCancelDownload,
    this.downloadProgress,
  });

  bool get _isFree => (priceManat ?? 0) <= 0;

  /// A book that's already owned has nothing left to sell — the "Satyn al"
  /// button is replaced by a passive "Satyn alnan" badge. A subscriber
  /// still sees a live buy button: buying outlives the subscription.
  bool get _owned => access == BookAccess.purchased;

  @override
  Widget build(BuildContext context) {
    final downloading = downloadProgress != null;
    final showBuySide = !_isFree;
    return Row(
      children: [
        Expanded(
          child: downloading ? _buildDownloading(context) : _buildRead(context),
        ),
        if (showBuySide) ...[
          const SizedBox(width: 10),
          Expanded(child: _owned ? _buildOwnedBadge() : _buildBuy(context)),
        ],
      ],
    );
  }

  Widget _buildRead(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: access == null ? null : onRead,
        icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedBookOpen01,
            color: Colors.white,
            size: 18),
        label: Text(BookDetailStrings.read,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  /// Progress plus a tap-to-cancel — a 50 MB CBZ on a slow connection has
  /// to be abandonable without leaving the page.
  Widget _buildDownloading(BuildContext context) {
    final progress = downloadProgress!.clamp(0.0, 1.0);
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onCancelDownload,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                // An indeterminate spinner until the server tells us the
                // total; a 0-length bar would read as "stuck".
                value: progress > 0 ? progress : null,
                strokeWidth: 2.2,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuy(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: access == null ? null : onBuy,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 1.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(BookDetailStrings.buy,
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(
              BookDetailStrings.priceValue(priceManat ?? 0),
              style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedBadge() {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: AppColors.grey2,
              size: 17),
          const SizedBox(width: 7),
          Text(BookDetailStrings.purchasedBadge,
              style: TextStyle(
                  color: AppColors.grey2,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
