import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

enum PaymentMethodChoice { promoCode, bankCard, store }

/// The first step of checkout on [SubscriptionScreen] — asks how the user
/// wants to pay before anything is actually charged, rather than the old
/// "tap Subscribe and it just happens" flow.
class PaymentMethodSheet extends StatelessWidget {
  const PaymentMethodSheet({super.key, this.showStore = false});

  /// Adds the [PaymentMethodChoice.store] row — App Store/Google Play via
  /// RevenueCat. Off by default: the local bank flow only accepts
  /// Turkmenistan bank cards, so this only makes sense to show once the
  /// caller has confirmed (via `RevenueCatApiService.getConfig`) that the
  /// signed-in user is on the foreign/store billing path.
  final bool showStore;

  static Future<PaymentMethodChoice?> show(BuildContext context,
      {bool showStore = false}) {
    return showModalBottomSheet<PaymentMethodChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentMethodSheet(showStore: showStore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Text(PaymentStrings.choosePaymentMethodTitle,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _OptionRow(
              icon: HugeIcons.strokeRoundedDiscountTag01,
              label: PaymentStrings.payWithPromoCode,
              onTap: () =>
                  Navigator.pop(context, PaymentMethodChoice.promoCode),
            ),
            Divider(color: AppColors.border, height: 1),
            _OptionRow(
              icon: HugeIcons.strokeRoundedCreditCard,
              label: PaymentStrings.payWithCard,
              onTap: () => Navigator.pop(context, PaymentMethodChoice.bankCard),
            ),
            if (showStore) ...[
              Divider(color: AppColors.border, height: 1),
              _OptionRow(
                icon: HugeIcons.strokeRoundedStore01,
                label: PaymentStrings.payWithStore,
                onTap: () => Navigator.pop(context, PaymentMethodChoice.store),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  const _OptionRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Center(
                  child:
                      HugeIcon(icon: icon, color: AppColors.primary, size: 19)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600))),
            HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.grey3,
                size: 18),
          ],
        ),
      ),
    );
  }
}
