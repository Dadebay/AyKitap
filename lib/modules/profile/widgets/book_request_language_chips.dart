import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// [BookRequestSheet]'s language chip row — split out to keep that file
/// under the 200-line limit.
class BookRequestLanguageChips extends StatelessWidget {
  final List<String> languages;
  final String selected;
  final ValueChanged<String> onSelected;

  const BookRequestLanguageChips({
    super.key,
    required this.languages,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((l) {
        final isSelected = l == selected;
        return GestureDetector(
          onTap: () => onSelected(l),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(l,
                style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.grey1,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}
