import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_enums.dart';

/// One font option, styled to match the level tiles below: a big "Aa" preview
/// rendered in the actual typeface over the font's name. Filled accent when
/// selected, outlined when idle.
class ReaderFontTile extends StatelessWidget {
  final ReaderFontFamily family;
  final bool selected;
  final VoidCallback onTap;

  const ReaderFontTile(
      {super.key,
      required this.family,
      required this.selected,
      required this.onTap});

  String get name => switch (family) {
        ReaderFontFamily.sanFrancisco => 'San Francisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'Noto Serif',
        ReaderFontFamily.openSans => 'Open Sans',
      };

  String get fontFamily => switch (family) {
        ReaderFontFamily.sanFrancisco => 'SanFrancisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'NotoSerif',
        ReaderFontFamily.openSans => 'OpenSans',
      };

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                  color: fg,
                  fontFamily: fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.grey2,
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
