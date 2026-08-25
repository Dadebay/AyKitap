import 'package:flutter/material.dart';

/// Trims the blank print margins a PDF page carries down each side, so the
/// text block fills the screen's width instead of floating in the middle of
/// two empty strips.
///
/// It does this without touching how the page is rendered: [child] (the
/// [PdfViewer]) is handed a viewport [fraction] wider than the real one on
/// each side and the overflow is clipped away. The viewer fits the page to
/// the box it's given, so a wider box means a bigger page, and the clip
/// takes the difference off both edges evenly.
///
/// Doing it here rather than through pdfrx's zoom is deliberate. pdfrx
/// recomputes the zoom when it jumps to the initial page
/// (`_calcMatrixForPage` → `_calcMatrixForRect`), capping it at
/// `viewportWidth / (pageWidth + 2 * params.margin)` — fit-the-whole-page-
/// width — so a `calculateInitialZoom` that asks for anything larger is
/// silently discarded and the page can never bleed past the edges that way.
/// Sizing the viewport is the one lever pdfrx doesn't override.
///
/// [fraction] is the share of the *page's own* width taken off each side, so
/// 0.05 hides the outer 5% of the page left and right and shows the middle
/// 90% — which is the number a margin is naturally described by. (Measured
/// against the viewport instead the overhang is slightly larger,
/// `f / (1 - 2f)`, since the page it's cropped from is the bigger of the
/// two.) Zero returns [child] untouched — no clip layer, no changed
/// constraints — which is what an image-only book (a scan or a manga,
/// already printed edge to edge, with no blank margin to spare) opens with.
class PdfMarginCropBox extends StatelessWidget {
  final double fraction;
  final Widget child;

  const PdfMarginCropBox({
    super.key,
    required this.fraction,
    required this.child,
  });

  /// The widest crop the settings slider can ask for — a page whose margins
  /// run past this is unusual enough that cutting further would start eating
  /// the text itself.
  static const double maxFraction = 0.12;

  @override
  Widget build(BuildContext context) {
    final crop = fraction.clamp(0.0, maxFraction);
    if (crop <= 0) return child;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Both edges are cropped, hence the doubled fraction: to keep the
          // middle (1 - 2f) of the page filling the viewport, the page has to
          // be laid out 1/(1 - 2f) times as wide as the viewport is.
          final width = constraints.maxWidth / (1 - crop * 2);
          return OverflowBox(
            alignment: Alignment.center,
            minWidth: width,
            maxWidth: width,
            minHeight: constraints.maxHeight,
            maxHeight: constraints.maxHeight,
            child: child,
          );
        },
      ),
    );
  }
}
