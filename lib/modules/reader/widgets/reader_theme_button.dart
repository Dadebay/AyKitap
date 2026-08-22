import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_enums.dart';

/// iOS-style theme swatch: just the page colour, no label — the selected one
/// carries a ring plus a checkmark instead.
class ReaderThemeButton extends StatelessWidget {
  final ReaderThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const ReaderThemeButton(
      {super.key,
      required this.mode,
      required this.selected,
      required this.onTap});

  // The swatch keeps its own fixed reader-page colour regardless of app theme.
  Color get bgColor => switch (mode) {
        ReaderThemeMode.white => Colors.white,
        ReaderThemeMode.sepia => const Color(0xFFf5ebda),
        ReaderThemeMode.dark => const Color(0xFF1C1C1E),
        ReaderThemeMode.black => Colors.black,
      };

  // Contrasting colour for the checkmark against this swatch's own fill.
  Color get checkColor => switch (mode) {
        ReaderThemeMode.white || ReaderThemeMode.sepia => Colors.black87,
        _ => Colors.white,
      };

  String get semanticLabel => switch (mode) {
        ReaderThemeMode.white => ReaderStrings.themeWhite,
        ReaderThemeMode.sepia => ReaderStrings.themeSepia,
        ReaderThemeMode.dark => ReaderStrings.themeDark,
        ReaderThemeMode.black => ReaderStrings.themeBlack,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: selected
              ? HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  color: checkColor,
                  size: 18)
              : null,
        ),
      ),
    );
  }
}
