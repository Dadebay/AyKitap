import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../navigation/app_hero_tags.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// The chrome drawn around a book cover: corner radius, drop shadows and an
/// optional hairline border.
///
/// A shelf card and the detail page's centred cover carry the same artwork
/// under very different chrome — 6px corners under a soft 10px shadow on the
/// shelf, 8px corners under a lifted 36px shadow on the detail page. Flutter
/// shows the *destination* widget for the whole Hero flight, so without this
/// the cover left the shelf already wearing the detail page's heavy shadow,
/// visibly snapping on the first frame of the tap. Keeping the chrome in a
/// lerpable value lets [BookCoverHero] interpolate it across the flight.
@immutable
class BookCoverStyle {
  const BookCoverStyle({
    required this.borderRadius,
    this.shadows = const <BoxShadow>[],
    this.border,
  });

  final double borderRadius;
  final List<BoxShadow> shadows;
  final BoxBorder? border;

  static BookCoverStyle lerp(BookCoverStyle a, BookCoverStyle b, double t) {
    return BookCoverStyle(
      borderRadius:
          lerpDouble(a.borderRadius, b.borderRadius, t) ?? b.borderRadius,
      // Pads the shorter list with fully transparent shadows, so a card with
      // one shadow growing into a detail cover with two fades the second one
      // in rather than popping it.
      shadows:
          BoxShadow.lerpList(a.shadows, b.shadows, t) ?? const <BoxShadow>[],
      border: BoxBorder.lerp(a.border, b.border, t),
    );
  }
}

/// One book cover, and the shared-element flight that carries it between a
/// shelf card and [CatalogBookDetailScreen].
///
/// Every catalogue surface builds its cover through this widget so the two
/// ends of a flight are the same kind of thing: only [style] and the laid-out
/// size differ, and the flight interpolates both.
class BookCoverHero extends StatelessWidget {
  const BookCoverHero({
    super.key,
    required this.tag,
    required this.style,
    required this.child,
    this.width,
    this.height,
  });

  /// Null disables the Hero entirely — for a surface that has no counterpart
  /// on the detail page (a grid that never pushes it, say).
  final String? tag;

  final BookCoverStyle style;

  /// The artwork: a [NetworkCoverImage] or a placeholder.
  final Widget child;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final surface = _BookCoverSurface(
      style: style,
      width: width,
      height: height,
      child: child,
    );
    final heroTag = tag;
    if (heroTag == null || AppMotion.reduceMotion(context)) return surface;
    return Hero(
      tag: heroTag,
      createRectTween: AppHeroTags.straightRectTween,
      transitionOnUserGestures: true,
      flightShuttleBuilder: _flightShuttle,
      child: surface,
    );
  }

  /// Draws the cover for the duration of a flight.
  ///
  /// `animation` here is the *deeper* route's own animation, so 0 always
  /// means the shelf card and 1 always means the detail page, whichever
  /// direction the flight is going — the push/pop difference is only which
  /// context is `from` and which is `to`.
  static Widget _flightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final push = direction == HeroFlightDirection.push;
    final shallowContext = push ? fromHeroContext : toHeroContext;
    final deepContext = push ? toHeroContext : fromHeroContext;
    final shallow = _surfaceOf(shallowContext);
    final deep = _surfaceOf(deepContext);
    if (shallow == null || deep == null) {
      return (toHeroContext.widget as Hero).child;
    }

    // Built once, at one fixed size, and scaled by [FittedBox] for the rest
    // of the flight. [NetworkCoverImage] derives its decode resolution from
    // its constraints, and the Hero drives those with a new rect every frame
    // — left to itself it re-resolved (and re-decoded) the cover on all ~18
    // frames of the flight, which is what made the flight stutter.
    final artwork = _stableArtwork(
      deep.child,
      _sizeOf(deepContext) ?? _sizeOf(shallowContext) ?? const Size(152, 224),
    );

    return AnimatedBuilder(
      animation: animation,
      child: artwork,
      builder: (context, child) => _BookCoverSurface(
        style: BookCoverStyle.lerp(shallow.style, deep.style, animation.value),
        child: child!,
      ),
    );
  }

  static _BookCoverSurface? _surfaceOf(BuildContext context) {
    final widget = context.widget;
    if (widget is! Hero) return null;
    final child = widget.child;
    return child is _BookCoverSurface ? child : null;
  }

  static Size? _sizeOf(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }

  static Widget _stableArtwork(Widget child, Size size) => FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(width: size.width, height: size.height, child: child),
      );
}

class _BookCoverSurface extends StatelessWidget {
  const _BookCoverSurface({
    required this.style,
    required this.child,
    this.width,
    this.height,
  });

  final BookCoverStyle style;
  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(style.borderRadius);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: radius,
        boxShadow: style.shadows,
        border: style.border,
      ),
      child: child,
    );
  }
}
