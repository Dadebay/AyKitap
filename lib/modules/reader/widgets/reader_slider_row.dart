import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

/// Full-width slider row: small leading icon, track, larger trailing icon.
/// Reused for both brightness and the eye-care filter; [min] lets the
/// eye-care slider reach fully off (0) while brightness bottoms out at 0.1.
/// Shared verbatim by the PDF and CBZ settings sheets, which used to each
/// carry an identical copy.
class ReaderSliderRow extends StatelessWidget {
  final List<List<dynamic>> leadingIcon;
  final List<List<dynamic>> trailingIcon;
  final double value;
  final double min;
  final ValueChanged<double> onChanged;

  const ReaderSliderRow({
    super.key,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.value,
    required this.min,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          HugeIcon(icon: leadingIcon, color: AppColors.grey3, size: 15),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.13),
              ),
              child: Slider(
                  value: value.clamp(min, 1.0), min: min, onChanged: onChanged),
            ),
          ),
          HugeIcon(icon: trailingIcon, color: AppColors.grey1, size: 21),
        ],
      ),
    );
  }
}
