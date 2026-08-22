import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// One tappable channel row in [ContactUsSheet] — icon, label and an
/// optional value (Telegram handle, phone number, email), or just the label
/// for the two policy-link rows.
class ContactRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const ContactRow(
      {super.key,
      required this.icon,
      required this.label,
      this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Center(
                  child:
                      HugeIcon(icon: icon, color: AppColors.primary, size: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: AppColors.grey2,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.grey3,
                size: 16),
          ],
        ),
      ),
    );
  }
}
