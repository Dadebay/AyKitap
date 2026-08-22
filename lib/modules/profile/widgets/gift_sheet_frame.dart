import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A subtle, constantly moving light around the sheet — it gives the gift
/// flow a celebratory focus without using a heavyweight video or Lottie asset.
class GiftSheetFrame extends StatelessWidget {
  const GiftSheetFrame(
      {super.key, required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(28));
    final angle = progress * 6.28318530718;
    final colors = [
      AppColors.primary,
      const Color(0xFFF6C56D),
      const Color(0xFFB45CFF),
      const Color(0xFF4AB7FF),
      AppColors.primary,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient:
            SweepGradient(colors: colors, transform: GradientRotation(angle)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .24),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 1.5, left: 1.5, right: 1.5),
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: AppColors.surface, borderRadius: radius),
          child: child,
        ),
      ),
    );
  }
}
