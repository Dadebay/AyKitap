import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// [BookPurchaseScreen]'s price/balance breakdown card, plus the
/// insufficient-balance note shown under it when [balance] doesn't cover
/// [price].
class BookPurchasePriceCard extends StatelessWidget {
  final int price;
  final int? balance;
  const BookPurchasePriceCard(
      {super.key, required this.price, required this.balance});

  bool get _enough => balance != null && balance! >= price;

  @override
  Widget build(BuildContext context) {
    final balance = this.balance;
    final enough = _enough;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _row(PaymentStrings.bookPrice, PaymentStrings.manat(price)),
              const SizedBox(height: 12),
              _row(
                PaymentStrings.yourBalance,
                balance != null ? PaymentStrings.manat(balance) : '…',
                valueColor: enough ? AppColors.grey1 : Colors.redAccent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.border, height: 1),
              ),
              _row(
                PaymentStrings.afterPurchase,
                enough
                    ? PaymentStrings.manat(balance! - price)
                    : PaymentStrings.notEnough,
                bold: true,
                valueColor: enough ? AppColors.white : Colors.redAccent,
              ),
            ],
          ),
        ),
        if (!enough) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: Colors.redAccent,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(PaymentStrings.balanceInsufficientNote,
                    style: TextStyle(
                        color: AppColors.grey2, fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: AppColors.grey2,
                fontSize: bold ? 14.5 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? AppColors.grey1,
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }
}
