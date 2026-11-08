import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// [SendGiftSheet]'s numbered step label — a small circled digit + text.
class GiftSectionLabel extends StatelessWidget {
  final String label;
  final String step;
  const GiftSectionLabel(this.label, {super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
              color: AppColors.grey1,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
