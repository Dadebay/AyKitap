import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// The book cover thumbnail in [ChapterListSheet]'s header — a placeholder
/// icon when there's no catalogue cover (an imported file) or the asset
/// fails to load.
class ChapterCover extends StatelessWidget {
  final String? coverImage;
  const ChapterCover({super.key, required this.coverImage});

  @override
  Widget build(BuildContext context) {
    const w = 46.0, h = 62.0;
    if (coverImage == null || coverImage!.isEmpty) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.menu_book_rounded, color: AppColors.grey3, size: 22),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        coverImage!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: w,
          height: h,
          color: AppColors.card,
          child:
              Icon(Icons.menu_book_rounded, color: AppColors.grey3, size: 22),
        ),
      ),
    );
  }
}
