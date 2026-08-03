import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// [CatalogAuthorDetailScreen]'s hero — the author's photo shown whole,
/// edge to edge.
///
/// Author photos come in every aspect ratio, so the sharp copy is fitted
/// with [BoxFit.contain] (never cropped through a face) and a blurred,
/// darkened copy of the same photo fills whatever width is left over. That
/// leftover is what used to read as dead black space beside the old 128px
/// circular portrait: now the sides are the photo itself, out of focus.
///
/// Flat layers only — a solid scrim over the blur instead of a fade
/// gradient, with the bottom corners rounded so the hero ends on a
/// deliberate edge against [AppColors.bg].
class CatalogAuthorHeaderArt extends StatelessWidget {
  const CatalogAuthorHeaderArt({super.key, required this.imageUrl});

  final String? imageUrl;

  static const double _height = 300;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  NetworkCoverImage(url: url, placeholder: (_) => Container(color: AppColors.card)),
                  // Blurs everything painted above (the cover copy), so the
                  // filler reads as depth rather than a second picture
                  // competing with the sharp one.
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      // Tinted with [AppColors.bg] rather than plain black so
                      // the filler settles toward the page behind it in both
                      // themes instead of turning a light UI's hero muddy.
                      child: Container(color: AppColors.bg.withValues(alpha: 0.45)),
                    ),
                  ),
                  NetworkCoverImage(url: url, fit: BoxFit.contain, placeholder: (_) => const SizedBox.shrink()),
                ],
              )
            : _avatarPlaceholder(),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: AppColors.card,
        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey3, size: 48)),
      );
}
