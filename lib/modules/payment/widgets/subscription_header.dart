import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// [SubscriptionScreen]'s top block — logo/title/subtitle, plus the "active
/// subscription" badge when [expiresAt] is set.
class SubscriptionHeader extends StatelessWidget {
  final DateTime? expiresAt;
  const SubscriptionHeader({super.key, required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final expiresAt = this.expiresAt;
    return Column(
      children: [
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Center(
                child: ClipOval(
                  child: Image.asset('assets/images/logo.webp',
                      width: 36, height: 36, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              PaymentStrings.unlimitedAccessTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              PaymentStrings.unlimitedAccessSubtitle,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        if (expiresAt != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    color: AppColors.primary,
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PaymentStrings.activeSubscription,
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                      Text(
                          PaymentStrings.activeUntil(
                              DateFormat.yMMMd().format(expiresAt)),
                          style:
                              TextStyle(color: AppColors.grey2, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
