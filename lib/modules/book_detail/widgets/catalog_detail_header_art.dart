import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/network_cover_image.dart';

/// [CatalogBookDetailScreen]'s equivalent of [DetailHeaderArt] — same
/// blurred-backdrop-plus-sharp-cover hero, but built on a real cover URL
/// (via [NetworkCoverImage]) instead of a bundled asset, since a catalogue
/// book has no `coverColor` to tint the blur with.
class CatalogDetailHeaderArt extends StatelessWidget {
  const CatalogDetailHeaderArt({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String? imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final isDark = AppTheme.instance.isDark;
    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            NetworkCoverImage(
                url: url, placeholder: (_) => Container(color: AppColors.card))
          else
            Container(color: AppColors.card),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
              child: Container(color: AppColors.bg.withValues(alpha: 0.25)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.bg.withValues(alpha: 0.4),
                  AppColors.bg
                ],
                stops: const [0.4, 0.82, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 65,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: Container(
                  width: 152,
                  height: 224,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 36,
                                spreadRadius: 2,
                                offset: const Offset(0, 18)),
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ]
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 36,
                                spreadRadius: 2,
                                offset: const Offset(0, 18)),
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: url != null && url.isNotEmpty
                        ? NetworkCoverImage(
                            url: url, placeholder: (_) => _coverPlaceholder())
                        : _coverPlaceholder(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Center(
      child: HugeIcon(
          icon: HugeIcons.strokeRoundedBook02,
          color: AppColors.grey3,
          size: 36));
}
