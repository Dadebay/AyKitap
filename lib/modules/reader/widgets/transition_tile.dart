import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// One page-transition option: the artwork on a square tile, with its name
/// beneath — filled solid when selected, outlined when idle.
class TransitionTile extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TransitionTile(
      {super.key,
      required this.asset,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 78,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Center(
              // The PNGs are flat silhouettes with a baked-in blue tint, so
              // srcIn repaints them in the app's palette and lets the same
              // artwork read on both the filled and idle tile.
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : AppColors.grey1,
                  BlendMode.srcIn,
                ),
                child: Image.asset(asset,
                    width: 46, height: 46, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.grey3,
              fontSize: 10.5,
              height: 1.25,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
