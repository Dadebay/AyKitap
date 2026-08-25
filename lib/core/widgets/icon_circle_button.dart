import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';

/// A tappable icon in a filled circle or rounded square — merges what used
/// to be two near-identical private widgets (`_IconBtn` on Home,
/// `_RoundIconBtn` on Book Detail). Defaults match `_IconBtn`'s rounded-card
/// look; pass [backgroundColor]/[iconColor]/no [borderRadius] for the
/// circular overlay-on-image look `_RoundIconBtn` had.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    this.filledIcon,
    this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
  });

  final List<List<dynamic>> icon;

  /// A solid/bold [IconData] to render instead of [icon] — e.g. a filled
  /// heart for a "liked" state, where the outline HugeIcons style has no
  /// bold counterpart in the free icon set this app ships with.
  final IconData? filledIcon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.card,
          shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
        ),
        child: filledIcon != null
            ? Icon(filledIcon,
                color: iconColor ?? AppColors.grey1, size: iconSize)
            : HugeIcon(
                icon: icon,
                color: iconColor ?? AppColors.grey1,
                size: iconSize),
      ),
    );
  }
}
