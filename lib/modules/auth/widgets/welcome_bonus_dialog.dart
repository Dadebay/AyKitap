import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen confetti celebration shown once, right after a brand-new
/// account finishes signup — announces the backend's automatic welcome
/// credit (a manat balance instead of a time-limited free trial), spendable
/// on either a week of Plus or a single book. Same shape as
/// [SubscriptionSuccessDialog], reused here rather than shared: that one is
/// keyed to a purchased plan's label, this one to a balance amount, and the
/// two are unlikely to ever need to change in lockstep.
class WelcomeBonusDialog extends StatelessWidget {
  final String amount;
  const WelcomeBonusDialog({super.key, required this.amount});

  static Future<void> show(BuildContext context, {required String amount}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => WelcomeBonusDialog(amount: amount),
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
                          icon: HugeIcons.strokeRoundedGift,
                          color: AppColors.primary,
                          size: 34)),
                ),
                const SizedBox(height: 18),
                Text(AuthStrings.welcomeBonusTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  AuthStrings.welcomeBonusBody(amount),
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
                    child: Text(AuthStrings.welcomeBonusCta,
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
