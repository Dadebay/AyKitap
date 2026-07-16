import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// A tinted circular icon badge, used as the leading visual on every
/// profile entry card so they all read as one family.
Widget profileIconCircle(List<List<dynamic>> icon, {Color? color}) {
  final c = color ?? AppColors.primary;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
    child: Center(child: HugeIcon(icon: icon, color: c, size: 20)),
  );
}

/// Shared shell for every row on the Profile tab (subscription, streak,
/// finance, settings, notes, book request) so they share one padding,
/// radius, and title/subtitle typography instead of each drifting apart.
class ProfileEntryCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final bool highlighted;
  final VoidCallback onTap;

  const ProfileEntryCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.extra,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = highlighted ? AppColors.primary : AppColors.grey1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: highlighted ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: titleColor, fontSize: 14.5, fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: TextStyle(color: AppColors.grey2, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: highlighted ? AppColors.primary : AppColors.grey3, size: 18),
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: 14),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}
