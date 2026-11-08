import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/book_cover_hero.dart';
import '../../../core/widgets/network_cover_image.dart';

/// A ranked-list row's cover — a fixed width at the app's usual book aspect
/// ratio (0.62, same as `LibraryBookCover`) rather than a squashed 52×74
/// box. Shadow lives on an outer [DecoratedBox] and the image is clipped by
/// an inner [ClipRRect] — put both on the same box and `clipBehavior` cuts
/// the shadow off along with everything else outside the corners.
class BookCoverThumb extends StatelessWidget {
  final String? imageUrl;
  final String? heroTag;
  const BookCoverThumb({super.key, this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return SizedBox(
      width: 54,
      child: AspectRatio(
        aspectRatio: 0.62,
        child: BookCoverHero(
          tag: heroTag,
          style: BookCoverStyle(
            borderRadius: 8,
            // Dark mode: a black shadow would just vanish into the dark
            // page background, so the cover gets a soft light glow instead;
            // light mode keeps the usual dark drop shadow.
            shadows: [
              BoxShadow(
                color: (AppTheme.instance.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: AppTheme.instance.isDark ? 0.18 : 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // The same placeholder covers both "still loading" and "no
          // cover url" — leaving it blank (as before) is what made a
          // cover read as missing until the network image finished.
          child: hasImage
              ? NetworkCoverImage(
                  url: ApiConfig.resolveImageUrl(url),
                  placeholder: (_) => _coverPlaceholder())
              : _coverPlaceholder(),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Center(
      child: HugeIcon(
          icon: HugeIcons.strokeRoundedBook02,
          color: AppColors.grey3,
          size: 20));
}
