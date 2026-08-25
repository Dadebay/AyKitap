import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

/// Placeholder shown in place of Home's collection sections while
/// [HomeDataService] is still fetching — a handful of generic "section"
/// skeletons (title bar + a horizontal row of card-shaped blocks) under one
/// shared shimmer sweep, since the real section count/shape isn't known
/// until the response actually lands.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++) _sectionSkeleton(),
        ],
      ),
    );
  }

  Widget _sectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: _block(width: 150, height: 16, radius: 6),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(left: 6, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _block(width: 100, height: 155, radius: 10),
                  const SizedBox(height: 6),
                  _block(width: 80, height: 10, radius: 4),
                  const SizedBox(height: 4),
                  _block(width: 60, height: 9, radius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _block(
      {required double width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Placeholder for [BannerCarousel] while its own data is still loading —
/// same rounded-rect shape as the real banner card, under its own shimmer
/// sweep (kept separate from [HomeShimmer] since the banner and the
/// collection sections resolve independently).
class BannerShimmer extends StatelessWidget {
  const BannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.surface,
        child: Container(
            height: 168,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20))),
      ),
    );
  }
}
