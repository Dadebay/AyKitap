import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/book_cover_hero.dart';
import '../../../core/widgets/network_cover_image.dart';

/// [CatalogBookDetailScreen]'s equivalent of [DetailHeaderArt] — same
/// blurred-backdrop-plus-sharp-cover hero, but built on a real cover URL
/// (via [NetworkCoverImage]) instead of a bundled asset, since a catalogue
/// book has no `coverColor` to tint the blur with.
class CatalogDetailHeaderArt extends StatefulWidget {
  const CatalogDetailHeaderArt({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  final String? imageUrl;
  final String heroTag;

  @override
  State<CatalogDetailHeaderArt> createState() => _CatalogDetailHeaderArtState();
}

class _CatalogDetailHeaderArtState extends State<CatalogDetailHeaderArt> {
  Animation<double>? _routeAnimation;
  bool _showBackdrop = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) return;
    _routeAnimation?.removeStatusListener(_onRouteStatusChanged);
    _routeAnimation = animation;
    _showBackdrop = animation == null || animation.isCompleted;
    animation?.addStatusListener(_onRouteStatusChanged);
  }

  void _onRouteStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || _showBackdrop || !mounted) {
      return;
    }
    setState(() => _showBackdrop = true);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    final isDark = AppTheme.instance.isDark;
    return SizedBox(
      // `double.infinity` (not MediaQuery's width) so this fills whatever
      // its parent gives it — correct in split-screen and on a foldable's
      // inner display, where the screen is wider than this widget's slot.
      width: double.infinity,
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: AppMotion.crossfade,
            switchInCurve: AppMotion.easeOut,
            // Both branches are wrapped in [SizedBox.expand], and that is
            // load-bearing: AnimatedSwitcher's default layout builder puts
            // its children in a `StackFit.loose` Stack, which hands them
            // *loose* constraints. [NetworkCoverImage] passes no explicit
            // width/height, so under loose constraints the image sized to
            // its own intrinsic aspect ratio — i.e. it behaved like
            // BoxFit.contain regardless of `fit`, leaving a ~257px-wide
            // backdrop letterboxed in a 384px header. Expanding to tight
            // full-size constraints is what lets BoxFit.cover actually
            // crop-to-fill and reach both screen edges. The bare
            // [ColoredBox] branch needs it for the same reason: with no
            // child and loose constraints it collapses to 0x0.
            child: _showBackdrop && url != null && url.isNotEmpty
                ? SizedBox.expand(
                    key: ValueKey(url),
                    child: ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 10),
                        // Painted 20% oversized so the blur, which samples
                        // past its source's edges, has headroom to blur
                        // into instead of fading toward empty at the rim;
                        // the ClipRect trims the overflow back off.
                        child: Transform.scale(
                          scale: 1.2,
                          child: RepaintBoundary(
                            child: NetworkCoverImage(
                              url: url,
                              placeholder: (_) => ColoredBox(color: AppColors.card),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox.expand(
                    key: const ValueKey('deferred-cover-backdrop'),
                    child: ColoredBox(color: AppColors.card),
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.bg.withValues(alpha: 0.4), AppColors.bg],
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
              child: BookCoverHero(
                  tag: widget.heroTag,
                  width: 152,
                  height: 224,
                  style: BookCoverStyle(
                    borderRadius: 8,
                    shadows: isDark
                        ? [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 36, spreadRadius: 2, offset: const Offset(0, 18)),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
                          ]
                        : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: 2, offset: const Offset(0, 18)),
                            BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                  ),
                  child: url != null && url.isNotEmpty ? NetworkCoverImage(url: url, decodeCacheWidth: 650, placeholder: (_) => _coverPlaceholder()) : _coverPlaceholder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() => Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 36));
}
