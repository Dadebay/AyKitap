import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/settings_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [ContactUsSheet]'s grab handle + icon + title row.
class ContactUsHeader extends StatelessWidget {
  const ContactUsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle),
              child: Center(
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCustomerService01,
                      color: AppColors.primary,
                      size: 20)),
            ),
            const SizedBox(width: 12),
            Text(SettingsStrings.contactUs,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}
