import 'package:flutter/material.dart';

/// Colour-inverts its child when [enabled] — the PDF reader's night mode.
///
/// The matrix negates each channel (`-1 × c + 255`) and leaves alpha alone,
/// turning a black-on-white page into a white-on-black one. Applied over the
/// rendered pages rather than asked of the PDF engine, so it behaves the same
/// on both platforms; the surrounding gutter is already dark in this mode, so
/// only the pages themselves visibly change.
class PdfNightModeFilter extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const PdfNightModeFilter(
      {super.key, required this.enabled, required this.child});

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
