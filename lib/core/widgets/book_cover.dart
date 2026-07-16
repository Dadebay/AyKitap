import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A book cover thumbnail: rounded, clipped [Image.asset] over a card-color
/// background (the fallback tile while the image decodes / if it's missing).
/// The same rounded-cover-over-card pattern was rewritten separately in
/// Home's `_BookCard`/`_MiniBookCard`/`_RankedBookTile` and Book Detail's
/// `_MiniBookCard`.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(borderRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(imagePath, fit: fit),
      ),
    );
  }
}
