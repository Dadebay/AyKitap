import 'package:flutter/material.dart';
import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// "Balans ýeterlik däl" — one dialog for every paid action that finds the
/// balance short (a subscription plan in [SubscriptionScreen], a single
/// book in [BookPurchaseScreen] / the book detail CTA).
///
/// Returns true when the user chose to pay, which is the caller's cue to
/// start whichever money-in flow fits it — [startBalanceTopUp] for a book,
/// [PaymentMethodSheet] directly for a plan.
class InsufficientBalanceDialog extends StatelessWidget {
  /// What's missing, in manat. When null (or ≤ 0) the generic note is shown
  /// instead of the exact shortfall — a plan checkout knows the price but a
  /// balance that hasn't loaded yet doesn't give a meaningful difference.
  final int? shortfallManat;

  /// Overrides the explanatory line under the title. Defaults to the
  /// shortfall sentence, or [PaymentStrings.balanceInsufficientNote].
  final String? note;

  const InsufficientBalanceDialog({super.key, this.shortfallManat, this.note});

  static Future<bool> show(BuildContext context,
      {int? shortfallManat, String? note}) async {
    final pay = await showDialog<bool>(
      context: context,
      builder: (_) =>
          InsufficientBalanceDialog(shortfallManat: shortfallManat, note: note),
    );
    return pay == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    final shortfall = shortfallManat;
    final body = note ??
        (shortfall != null && shortfall > 0
            ? PaymentStrings.balanceShortfall(shortfall)
            : PaymentStrings.balanceInsufficientNote);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Image.asset(
              isDark
                  ? 'assets/images/balance_empty_dark.webp'
                  : 'assets/images/balance_empty_light.webp',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            PaymentStrings.balanceNotEnough,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(PaymentStrings.payNow,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(PaymentStrings.close,
                style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
