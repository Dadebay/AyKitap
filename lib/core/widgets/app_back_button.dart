import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';

/// The plain back-arrow `IconButton` repeated at the top of 15+ screens.
/// Defaults to `Navigator.pop`; pass [onPressed] to override (e.g. to pop
/// with a result).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.size = 22});

  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () => Navigator.pop(context),
      icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: size),
    );
  }
}
