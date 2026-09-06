import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../author/catalog_author_detail_screen.dart';

/// A circular story-ring avatar + name on a soft elevated chip — the
/// compact counterpart to [CatalogAuthorCard]'s tall photo card, for a Home
/// author rail where the ring itself is the point rather than a book-count
/// badge underneath.
class CatalogAuthorAvatar extends StatelessWidget {
  const CatalogAuthorAvatar({
    super.key,
    required this.authorId,
    required this.name,
    this.image,
    this.width = 104,
    this.diameter = 88,
  });

  final int authorId;
  final String name;
  final String? image;
  final double width;
  final double diameter;

  /// Ring stroke (2.4) + inner gap (2.4) on each side, twice over — the
  /// square the photo actually renders into. Passed to [NetworkCoverImage]
  /// explicitly rather than left to inherited [LayoutBuilder] constraints:
  /// this is what guarantees a true circle crop instead of the photo
  /// stretching to whatever box the nested padding/ClipOval chain measures.
  double get _photoSize => diameter - 4 * 2.4;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null && image!.isNotEmpty;
    final isDark = AppTheme.instance.isDark;
    return Semantics(
      label: name,
      button: true,
      child: PressableScale(
        onTap: () => context.push(CatalogAuthorDetailScreen(authorId: authorId)),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              isDark ? BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 10) : BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: diameter,
                height: diameter,
                padding: const EdgeInsets.all(2.4),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.coralPurple),
                child: Container(
                  padding: const EdgeInsets.all(2.4),
                  decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                  child: ClipOval(
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.resolveImageUrl(image!),
                          )
                        : _placeholder(),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => ColoredBox(
        color: AppColors.card,
        child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey3, size: 28)),
      );
}
