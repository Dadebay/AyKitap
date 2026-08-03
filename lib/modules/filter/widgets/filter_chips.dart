import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

class MultiChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const MultiChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.grey1,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class SortTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final T group;
  final ValueChanged<T?> onChanged;
  const SortTile(
      {super.key,
      required this.label,
      required this.value,
      required this.group,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            HugeIcon(
              icon: selected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              color: selected ? AppColors.primary : AppColors.grey3,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: selected ? AppColors.white : AppColors.grey2,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          ],
        ),
      ),
    );
  }
}
