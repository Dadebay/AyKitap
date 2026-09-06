import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// [BookPurchaseScreen]'s sticky bottom action — "Tassykla — N TMT" when the
/// balance covers [price], "Balans doldur" otherwise; a spinner mid-request.
class BookPurchaseConfirmButton extends StatelessWidget {
  final int price;
  final bool enough;
  final bool processing;
  final VoidCallback onConfirm;
  final VoidCallback onTopUp;

  const BookPurchaseConfirmButton({
    super.key,
    required this.price,
    required this.enough,
    required this.processing,
    required this.onConfirm,
    required this.onTopUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: processing ? null : (enough ? onConfirm : onTopUp),
          child: processing
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
              : Text(
                  enough ? PaymentStrings.confirmWithPrice(price) : PaymentStrings.topUpBalance,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
