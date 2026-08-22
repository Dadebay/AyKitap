import 'package:flutter/material.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// Full-bleed banner behind a ranked collection's [SliverAppBar] — the top
/// book's own cover, same as `CatalogRankShelfCard`'s card header. Carries
/// no text of its own; the collection name lives in `FlexibleSpaceBar.title`
/// instead so it collapses into the toolbar properly.
class RankedCollectionBanner extends StatelessWidget {
  final String? imageUrl;
  const RankedCollectionBanner({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        hasImage
            ? NetworkCoverImage(
                url: ApiConfig.resolveImageUrl(url),
                placeholder: (_) => Container(color: AppColors.card))
            : Container(color: AppColors.card),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.65)
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
