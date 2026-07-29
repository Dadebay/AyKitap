import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/network_cover_image.dart';

/// [CatalogAuthorDetailScreen]'s equivalent of [CatalogDetailHeaderArt] — the
/// author's own photo blurred full-bleed behind the hero, fading into
/// [AppColors.bg], with a sharp circular portrait centered in front (a
/// circle rather than the book detail's rectangular cover, since this is a
/// person, not a book). Falls back to a plain card-colored backdrop when
/// the author has no photo, so the layout doesn't shift either way.
class CatalogAuthorHeaderArt extends StatelessWidget {
  const CatalogAuthorHeaderArt({super.key, required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final isDark = AppTheme.instance.isDark;
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hasImage ? NetworkCoverImage(url: url, placeholder: (_) => Container(color: AppColors.card)) : Container(color: AppColors.card),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: AppColors.bg.withValues(alpha: 0.35)),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg.withValues(alpha: 0.5), AppColors.bg],
                stops: const [0.3, 0.8, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 40,
            child: Center(
              child: Container(
                width: 128,
                height: 128,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 4),
                  boxShadow: [
                    isDark
                        ? BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 28, spreadRadius: 1, offset: const Offset(0, 12))
                        : BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 28, spreadRadius: 1, offset: const Offset(0, 12)),
                  ],
                ),
                child: hasImage ? NetworkCoverImage(url: url, placeholder: (_) => _avatarPlaceholder()) : _avatarPlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() => Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey3, size: 40));
}
