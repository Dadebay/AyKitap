import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/models/book.dart';
import '../../../core/services/purchased_books_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/book_detail_strings.dart';

/// §10.1.7 + §10.2 — pinned bottom action. Subscribers / owners get "Oka";
/// everyone else sees the price and a "Satyn al" button. Watches both
/// entitlement sources directly so it flips the instant a purchase or a
/// fresh subscription lands, without the rest of the screen rebuilding.
class DetailStickyCta extends StatelessWidget {
  const DetailStickyCta({super.key, required this.book, required this.opening, required this.onRead, required this.onBuy});

  final Book book;
  final bool opening;
  final VoidCallback onRead;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final subscriptionActive = context.watch<SubscriptionService>().isActive;
    final purchased = context.watch<PurchasedBooksStore>().isPurchased(book.id);
    final canRead = subscriptionActive || purchased;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: canRead ? _readButton() : _buyRow(book),
        ),
      ),
    );
  }

  Widget _readButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: opening ? null : onRead,
        icon: opening
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
            : const HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: Colors.white, size: 20),
        label: Text(BookDetailStrings.read, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buyRow(Book book) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(BookDetailStrings.price, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
            const SizedBox(height: 2),
            Text(BookDetailStrings.priceValue(book.priceManat), style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: onBuy,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedShoppingBag01, color: Colors.white, size: 19),
              label: Text(BookDetailStrings.buy, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}
