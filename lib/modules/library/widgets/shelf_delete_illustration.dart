import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// The cover being deleted, with a trash badge on its corner — or a tinted
/// icon circle when there's no artwork to show. Used by the shelf-delete
/// confirmation dialog.
class ShelfDeleteIllustration extends StatelessWidget {
  const ShelfDeleteIllustration({super.key, this.coverUrl});

  final String? coverUrl;

  static const _danger = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
            color: _danger.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: const Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02, color: _danger, size: 32),
        ),
      );
    }
    return SizedBox(
      width: 72,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: NetworkCoverImage(
                url: url,
                placeholder: (_) => Container(color: AppColors.bg),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _danger,
                shape: BoxShape.circle,
                // Reads as a badge cut into the cover rather than a sticker
                // floating over it, whichever theme the card is painted in.
                border: Border.all(color: AppColors.card, width: 3),
              ),
              child: const Center(
                child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: Colors.white,
                    size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
