import 'package:flutter/material.dart';

import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/network_cover_image.dart';

/// Pushes a reader with Aýkitap's calm signature transition.
///
/// When opened from a catalogue detail page, the cover flies to the centre,
/// settles briefly, then dissolves into the actual reader. Other entry points
/// still receive the same subtle fade/scale transition without inventing a
/// fake cover. The reader child is kept stable behind the entrance layer so
/// PDF/EPUB initialization is never restarted by the animation.
Future<T?> pushReaderRoute<T>(
  BuildContext context, {
  required Widget reader,
  String? coverUrl,
  String? heroTag,
}) {
  final reduceMotion = AppMotion.reduceMotion(context);
  final hasCover = !reduceMotion &&
      coverUrl != null &&
      coverUrl.isNotEmpty &&
      heroTag != null &&
      heroTag.isNotEmpty;

  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      transitionDuration: reduceMotion ? AppMotion.instant : AppMotion.emphasis,
      reverseTransitionDuration:
          reduceMotion ? AppMotion.instant : AppMotion.standard,
      pageBuilder: (context, animation, secondaryAnimation) => _ReaderEntrance(
        coverUrl: hasCover ? coverUrl : null,
        heroTag: hasCover ? heroTag : null,
        child: reader,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.easeOut,
          reverseCurve: AppMotion.easeInOut,
        );
        if (reduceMotion) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _ReaderEntrance extends StatefulWidget {
  const _ReaderEntrance({
    required this.child,
    required this.coverUrl,
    required this.heroTag,
  });

  final Widget child;
  final String? coverUrl;
  final String? heroTag;

  @override
  State<_ReaderEntrance> createState() => _ReaderEntranceState();
}

class _ReaderEntranceState extends State<_ReaderEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.coverUrl != null && widget.heroTag != null) {
      _controller = AnimationController(
        vsync: this,
        duration: AppMotion.celebration,
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: widget.child),
        if (controller != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final exit = CurvedAnimation(
                  parent: controller,
                  curve: const Interval(0.55, 1, curve: AppMotion.easeOut),
                );
                return Opacity(
                  opacity: 1 - exit.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF11131D)
                          .withValues(alpha: 0.92 * (1 - exit.value)),
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + (0.035 * exit.value),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: Hero(
                tag: widget.heroTag!,
                createRectTween: AppHeroTags.straightRectTween,
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  direction,
                  fromContext,
                  toContext,
                ) =>
                    FadeTransition(
                  opacity: animation.drive(
                    Tween<double>(begin: 0.82, end: 1),
                  ),
                  child: toContext.widget,
                ),
                child: _ReaderCover(url: widget.coverUrl!),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReaderCover extends StatelessWidget {
  const _ReaderCover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 152,
        height: 224,
        decoration: BoxDecoration(
          color: const Color(0xFF242632),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 32,
              offset: Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: NetworkCoverImage(
          url: url,
          placeholder: (_) => const ColoredBox(color: Color(0xFF242632)),
        ),
      ),
    );
  }
}
