import 'dart:math' as math;

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
    this.alignment = Alignment.center,
  });

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = finite(width) ?? finite(constraints.maxWidth);
        final boxHeight = finite(height) ?? finite(constraints.maxHeight);
        // Only ever hand the decoder ONE dimension. `ResizeImage` (which is
        // what memCacheWidth/Height build under the hood) resizes to exactly
        // the sizes it is given, so passing both squashes the source's aspect
        // ratio — a portrait photo in a square avatar box came out visibly
        // stretched sideways, and no BoxFit could undo it because the
        // distortion already happened at decode time. With one dimension the
        // other scales proportionally; picking the larger side is what keeps
        // BoxFit.cover from decoding below the size it actually paints at.
        int px(double v) => (v * dpr).round();
        int? cacheWidth;
        int? cacheHeight;
        if (boxWidth != null && boxHeight != null) {
          cacheWidth = px(math.max(boxWidth, boxHeight));
        } else if (boxWidth != null) {
          cacheWidth = px(boxWidth);
        } else if (boxHeight != null) {
          cacheHeight = px(boxHeight);
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
