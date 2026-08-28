import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// Material's three-bucket width breakpoints — compact (a phone, portrait or
/// landscape), medium (a small tablet, or a foldable opened flat) and
/// expanded (a large tablet/desktop, or a foldable in book posture).
enum WindowWidthClass {
  compact,
  medium,
  expanded;

  static const _mediumBreakpoint = 600.0;
  static const _expandedBreakpoint = 840.0;

  static WindowWidthClass forWidth(double width) {
    if (width >= _expandedBreakpoint) return WindowWidthClass.expanded;
    if (width >= _mediumBreakpoint) return WindowWidthClass.medium;
    return WindowWidthClass.compact;
  }
}

/// A snapshot of the current window's size class, plus whatever a foldable's
/// hinge is reporting — the one place that reads
/// [MediaQueryData.displayFeatures] so the rest of the app never has to
/// parse a raw [DisplayFeature] list itself.
///
/// Two ends of the same [MediaQuery] read: [width] drives ordinary
/// breakpoint decisions (how many grid columns, whether to centre content);
/// [verticalHinge] is only non-null on an actual foldable that is currently
/// split left/right — a wide window on a tablet or desktop has no hinge at
/// all, and [width] alone is what those should react to.
@immutable
class WindowSizeClass {
  final WindowWidthClass width;
  final Size size;

  /// The bounds (in this [MediaQuery]'s logical-pixel coordinate space) of a
  /// hinge or fold that splits the window into a left and right half — a
  /// foldable open in "book" posture. Null on every device that isn't
  /// currently in that shape: a normal phone, a flat tablet, a foldable
  /// closed or fully unfolded flat, or one folded the other way (a top/bottom
  /// split rather than left/right).
  final Rect? verticalHinge;

  const WindowSizeClass({
    required this.width,
    required this.size,
    required this.verticalHinge,
  });

  bool get hasVerticalHinge => verticalHinge != null;

  /// Reads the nearest [MediaQuery] and returns its size class. Registers a
  /// dependency the same way [MediaQuery.of] does, so calling this from
  /// `build`/`didChangeDependencies` re-runs whenever the window is resized,
  /// rotated, or a fold's posture changes.
  factory WindowSizeClass.of(BuildContext context) =>
      WindowSizeClass._from(MediaQuery.of(context));

  factory WindowSizeClass._from(MediaQueryData mediaQuery) {
    return WindowSizeClass(
      width: WindowWidthClass.forWidth(mediaQuery.size.width),
      size: mediaQuery.size,
      verticalHinge: _findVerticalHinge(mediaQuery),
    );
  }

  /// A [DisplayFeature] "obstructs" (Flutter's own definition, shared with
  /// [DisplayFeatureSubScreen.avoidBounds]) when it has non-zero bounds or
  /// the device is reporting the half-open book posture even with a
  /// zero-width crease. Of those, the ones that matter here are the ones
  /// splitting the window *left/right* — spanning its full height — which is
  /// what turning a foldable book-wise (portrait, opened like a paperback)
  /// produces; a device folded the other way splits top/bottom instead and
  /// is deliberately not treated as a vertical hinge.
  static Rect? _findVerticalHinge(MediaQueryData mediaQuery) {
    for (final feature in mediaQuery.displayFeatures) {
      final isFoldOrHinge = feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge;
      if (!isFoldOrHinge) continue;
      final obstructs = feature.bounds.shortestSide > 0 ||
          feature.state == DisplayFeatureState.postureHalfOpened;
      if (!obstructs) continue;
      final spansFullHeight = feature.bounds.top <= 0 &&
          feature.bounds.bottom >= mediaQuery.size.height;
      if (spansFullHeight) return feature.bounds;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is WindowSizeClass &&
      other.width == width &&
      other.size == size &&
      other.verticalHinge == verticalHinge;

  @override
  int get hashCode => Object.hash(width, size, verticalHinge);
}
