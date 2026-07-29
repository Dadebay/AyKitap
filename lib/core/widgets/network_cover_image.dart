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
  const NetworkCoverImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
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
        final cacheWidth = finite(width) ?? finite(constraints.maxWidth);
        final cacheHeight = finite(height) ?? finite(constraints.maxHeight);
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: cacheWidth != null ? (cacheWidth * dpr).round() : null,
          memCacheHeight: cacheHeight != null ? (cacheHeight * dpr).round() : null,
          placeholder: (context, url) => placeholder(context),
          errorWidget: (context, url, error) => placeholder(context),
        );
      },
    );
  }
}
