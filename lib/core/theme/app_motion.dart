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

  /// A card's press-down and release-up legs of [PressableScale]. Asymmetric
  /// on purpose: the down leg should read as an immediate, almost-not-there
  /// reaction to the finger landing, while the release is long enough to see
  /// the card settle back.
  static const Duration pressDown = Duration(milliseconds: 90);
  static const Duration pressRelease = Duration(milliseconds: 150);

  /// One shelf's entrance ([StaggerFadeIn]) and the per-section stagger step.
  static const Duration sectionEntrance = Duration(milliseconds: 280);
  static const Duration sectionStagger = Duration(milliseconds: 45);

  /// Skeleton → content crossfade on Home.
  static const Duration crossfade = Duration(milliseconds: 180);

  /// A push with no shared cover to fly (a banner tap, a deep link) — plain
  /// fade only, no [Hero] involved, so it's shorter than [heroFlight].
  static const Duration linkFade = Duration(milliseconds: 200);

  /// Shared-element pushes ([HeroPageRoute]). Longer than [standard] because
  /// the cover crosses most of the screen and grows by half again on the way;
  /// Material's own container transform lands on the same 300ms.
  static const Duration heroFlight = Duration(milliseconds: 300);
  static const Duration emphasis = Duration(milliseconds: 420);
  static const Duration celebration = Duration(milliseconds: 700);

  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeInOut = Cubic(0.65, 0, 0.35, 1);

  /// System accessibility settings are authoritative. Decorative movement is
  /// removed and essential state changes use only a short fade.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
