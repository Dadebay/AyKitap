import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// Full-screen confetti celebration shown when [SubscriptionScreen]'s
/// purchase succeeds — replaces a plain snackbar so unlocking unlimited
/// reading doesn't get buried in one small line at the bottom of the screen.
class SubscriptionSuccessDialog extends StatelessWidget {
  final String planLabel;
  const SubscriptionSuccessDialog({super.key, required this.planLabel});

  static Future<void> show(BuildContext context, String planLabel) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => SubscriptionSuccessDialog(planLabel: planLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bursts across the whole screen, not just around the card — a
          // dialog-sized confetti burst reads as decoration on a box; a
          // full-bleed one reads as the screen itself celebrating.
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset('assets/animations/Confetti.json',
                  repeat: false, fit: BoxFit.cover),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedDiamond,
                          color: AppColors.primary,
                          size: 34)),
                ),
                const SizedBox(height: 18),
                Text(PaymentStrings.subscriptionSuccessTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  PaymentStrings.subscriptionActivated(planLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.grey1, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(PaymentStrings.subscriptionSuccessCta,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
