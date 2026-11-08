import 'package:flutter/material.dart';

/// Colour-inverts its child when [enabled] — the PDF reader's night mode.
///
/// The matrix negates each channel (`-1 × c + 255`) and leaves alpha alone,
/// turning a black-on-white page into a white-on-black one. Applied over the
/// rendered pages rather than asked of the PDF engine, so it behaves the same
/// on both platforms.
///
/// It inverts *everything* drawn inside it, which includes the viewer's own
/// gutter behind the pages — see [preInverted] for what that means for any
/// colour handed to a widget under this filter.
class PdfNightModeFilter extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const PdfNightModeFilter(
      {super.key, required this.enabled, required this.child});

  /// The colour to give a widget *inside* this filter so that it reaches the
  /// screen as [color].
  ///
  /// The gutter pdfrx paints behind the pages is drawn inside the filtered
  /// subtree, so handing it night mode's near-black directly had the filter
  /// turn it into a near-white: in paged mode the page sat in a bright white
  /// surround with the theme set to "Gije". Continuous scroll hid it, since
  /// it stacks pages edge to edge and leaves almost no gutter to see.
  ///
  /// Pre-inverting cancels the filter out, so the gutter lands on the colour
  /// that was actually asked for. Alpha is left alone, matching [_invert].
  static Color preInverted(Color color) => Color.from(
        alpha: color.a,
        red: 1 - color.r,
        green: 1 - color.g,
        blue: 1 - color.b,
      );

  static const _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) =>
      enabled ? ColorFiltered(colorFilter: _invert, child: child) : child;
}
