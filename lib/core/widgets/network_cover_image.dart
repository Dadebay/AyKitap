import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A network image with disk+memory caching (via `cached_network_image`) so
/// the same URL — a book cover, banner, or avatar — isn't re-downloaded
/// every time its widget rebuilds, scrolls back into view, or the screen
/// reopens. [placeholder] covers both the loading and error cases since
/// every call site here shows the same fallback tile for both.
class NetworkCoverImage extends StatelessWidget {
  final String url;
  final WidgetBuilder placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Forces a blurred full-screen copy to reuse the already-decoded cover.
  final int? decodeCacheWidth;

  /// Which part of the source survives a [BoxFit.cover] crop — worth moving
  /// off center for portraits, where the face sits above the middle.
  final Alignment alignment;
  const NetworkCoverImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.decodeCacheWidth,
    this.alignment = Alignment.center,
  });

  /// A decoded bitmap this large has no legitimate use at any of this
  /// widget's call sites — comfortably above the biggest real target (a
  /// full-bleed header backdrop on a large/high-DPR screen) while firmly
  /// ruling out a runaway width/height/DPR combination decoding a
  /// multi-thousand-pixel bitmap for what's ultimately a cover thumbnail.
  static const _maxDecodeDimension = 2048;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // Decoding at the widget's actual display size (rather than the source
    // image's full resolution) is what keeps each cached cover small enough
    // that Flutter's in-memory image cache can hold many of them at once —
    // otherwise a handful of full-res covers fill the cache and evict
    // everything else, which is what shows up as covers "reloading" (a
    // decode + placeholder flash) when navigating back to a screen. Falls
    // back to the incoming BoxConstraints when width/height aren't given
    // explicitly (most call sites size this via a parent Container/SizedBox).
    double? finite(double? v) => (v != null && v.isFinite) ? v : null;
    // Rounds to device pixels and floors at 1 — a 0 or negative target
    // (a collapsed layout mid-transition, say) would otherwise reach
    // CachedNetworkImage as an invalid decode size — then caps at
    // [_maxDecodeDimension] so an unusually large box/DPR combination can't
    // decode a bitmap far bigger than any real cover/banner/avatar needs.
    int px(double value) => (value * dpr).round().clamp(1, _maxDecodeDimension);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = finite(width) ?? finite(constraints.maxWidth);
        final boxHeight = finite(height) ?? finite(constraints.maxHeight);
        // Each axis is sized from its own dimension now, not from
        // `math.max(boxWidth, boxHeight)` — that flattened a portrait
        // cover's *height* (the larger of the two) into memCacheWidth,
        // decoding it noticeably wider than it's ever drawn. Independent
        // `if`s (not `else if`) so a call site that supplies both width
        // and height gets both passed to CachedNetworkImage, not just one
        // with the other left to scale proportionally off the source's own
        // aspect ratio.
        int? cacheWidth = decodeCacheWidth;
        int? cacheHeight;
        if (cacheWidth == null) {
          if (boxWidth != null) cacheWidth = px(boxWidth);
          if (boxHeight != null) cacheHeight = px(boxHeight);
        }
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          alignment: alignment,
          width: width,
          height: height,
          memCacheWidth: cacheWidth,
          memCacheHeight: cacheHeight,
          placeholder: (context, url) => placeholder(context),
          errorWidget: (context, url, error) => placeholder(context),
        );
      },
    );
  }
}
