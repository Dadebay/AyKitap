import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Celebrates a confirmed balance transfer before returning to the refreshed
/// profile. The confetti runs once and is deliberately outside the card so
/// the completed action feels substantial instead of like a small toast.
class GiftSuccessDialog extends StatelessWidget {
  const GiftSuccessDialog({super.key, required this.amount});

  final num amount;

  static Future<void> show(BuildContext context, {required num amount}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => GiftSuccessDialog(amount: amount),
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
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/animations/Confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(26),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: .28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .3),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: .22),
                        const Color(0xFFB45CFF).withValues(alpha: .2),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .36),
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedGift,
                      color: AppColors.primary,
                      size: 35,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  GiftStrings.sentSuccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  GiftStrings.sentDescription(amount),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      GiftStrings.successCta,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
