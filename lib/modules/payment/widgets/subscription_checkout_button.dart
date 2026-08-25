import 'package:flutter/material.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/models/tariff.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Sticky premium action. The button uses the Journey gradient only when a
/// real tariff can be purchased; disabled/loading states remain unambiguous.
class SubscriptionCheckoutButton extends StatelessWidget {
  const SubscriptionCheckoutButton({
    super.key,
    required this.processing,
    required this.hasSelection,
    required this.expiresAt,
    required this.selectedTariff,
    required this.onPressed,
  });

  final bool processing;
  final bool hasSelection;
  final DateTime? expiresAt;
  final Tariff? selectedTariff;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = !processing && hasSelection;
    final label = !hasSelection
        ? PaymentStrings.subscriptionTitle
        : expiresAt != null
            ? '${PaymentStrings.renew} — ${PaymentStrings.manat(selectedTariff!.price)}'
            : PaymentStrings.subscribeWithPrice(selectedTariff!.price);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.journeyMist,
        border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.55))),
      ),
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled || processing ? 1 : 0.46,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  enabled || processing ? AppGradients.journeyPrimary : null,
              color: enabled || processing ? null : AppColors.grey3,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppGradients.journeyRoseVioletColors.last
                            .withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ]
                  : const [],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: enabled ? onPressed : null,
                child: processing
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (hasSelection) ...[
                            const SizedBox(width: 9),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 19),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
