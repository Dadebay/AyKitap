import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GenreTag extends StatelessWidget {
  final String label;
  const GenreTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
