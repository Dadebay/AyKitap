import 'package:flutter/material.dart';
import '../../../core/models/tariff.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// [SubscriptionScreen]'s sticky bottom action — the plan's price, or
/// "Uzat" (renew) with the price when a subscription is already active.
class SubscriptionCheckoutButton extends StatelessWidget {
  final bool processing;
  final bool hasSelection;
  final DateTime? expiresAt;
  final Tariff? selectedTariff;
  final VoidCallback? onPressed;

  const SubscriptionCheckoutButton({
    super.key,
    required this.processing,
    required this.hasSelection,
    required this.expiresAt,
    required this.selectedTariff,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0),
          onPressed: (processing || !hasSelection) ? null : onPressed,
          child: processing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4))
              : Text(
                  !hasSelection
                      ? PaymentStrings.subscriptionTitle
                      : expiresAt != null
                          ? '${PaymentStrings.renew} — ${PaymentStrings.manat(selectedTariff!.price)}'
                          : PaymentStrings.subscribeWithPrice(
                              selectedTariff!.price),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
