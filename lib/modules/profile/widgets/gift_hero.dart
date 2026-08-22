import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [SendGiftSheet]'s top banner — logo, title, subtitle.
class GiftHero extends StatelessWidget {
  const GiftHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: .16),
            const Color(0xFF9B5CFF).withValues(alpha: .13),
            AppColors.card,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF121426),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .28),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
                child:
                    Image.asset('assets/images/logo.webp', fit: BoxFit.cover)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedGift,
                  color: AppColors.primary,
                  size: 21),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  GiftStrings.sheetTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            GiftStrings.sheetSubtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.grey2, fontSize: 12.5, height: 1.38),
          ),
        ],
      ),
    );
  }
}
