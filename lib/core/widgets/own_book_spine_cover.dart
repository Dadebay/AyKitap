import 'package:flutter/material.dart';
import '../models/own_book.dart';
import '../theme/app_gradients.dart';
import 'pressable_scale.dart';

/// Placeholder "spine" cover for a user-imported file — there's no real
/// artwork for these, just a format badge and the filename-derived title.
/// Reused (with slightly different chrome) by the Library "Öz Kitaplarym"
/// tab and by [OfflineLibraryScreen]'s grid.
class OwnBookSpineCover extends StatelessWidget {
  const OwnBookSpineCover({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
    this.borderRadius = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    this.wrapAspectRatio = true,
  });

  final OwnBook book;
  final VoidCallback onTap;

  /// Long-press action — the Library tab's "poz" for an imported file. The
  /// offline grid leaves it null (nothing there can be deleted mid-flight).
  final VoidCallback? onLongPress;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Library's shelf-grid slots need their own 0.62 aspect ratio; the
  /// offline grid already constrains cells via `childAspectRatio`.
  final bool wrapAspectRatio;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (book.format) {
      OwnBookFormat.pdf => AppGradients.pdfSpine,
      OwnBookFormat.cbz => AppGradients.cbzSpine,
      OwnBookFormat.epub => AppGradients.epubSpine,
    };
    final badge = switch (book.format) {
      OwnBookFormat.pdf => 'PDF',
      OwnBookFormat.cbz => 'CBZ',
      OwnBookFormat.epub => 'EPUB',
    };
    final content = PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(gradient: gradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
              Text(
                book.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
    return wrapAspectRatio
        ? AspectRatio(aspectRatio: 0.62, child: content)
        : content;
  }
}
