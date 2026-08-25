import 'package:flutter/material.dart';

/// Shared motion language for Aýkitap.
///
/// Keeping durations and curves here prevents each screen from inventing its
/// own animation rhythm. Readers should favour [quick]/[standard]; the longer
/// values are reserved for one-off transitions and celebrations.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration readerProgress = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasis = Duration(milliseconds: 420);
  static const Duration celebration = Duration(milliseconds: 700);

  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInOut = Cubic(0.65, 0, 0.35, 1);

  /// System accessibility settings are authoritative. Decorative movement is
  /// removed and essential state changes use only a short fade.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
