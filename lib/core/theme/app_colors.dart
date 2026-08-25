import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Every screen reads its colors from here instead of `Theme.of(context)`,
/// so switching [AppTheme.instance.isDark] and rebuilding the root widget is
/// enough to reskin the whole app.
class AppColors {
  AppColors._();

  static bool get _isDark => AppTheme.instance.isDark;

  static Color get primary => const Color(0xFFE8712C);
  static Color get primaryDark => const Color(0xFFBF5A1E);

  static Color get bg => _isDark ? const Color(0xFF13131A) : const Color(0xFFF6F6F9);
  static Color get surface => _isDark ? const Color(0xFF1C1C27) : const Color(0xFFFFFFFF);
  static Color get card => _isDark ? const Color(0xFF242433) : const Color(0xFFFFFFFF);
  static Color get border => _isDark ? const Color(0xFF2E2E42) : const Color(0xFFE3E3EA);

  // Named "white"/"grey*" for historical reasons (from the dark-only design)
  // but really mean "on-background" foreground tones — they flip to dark
  // text in light mode.
  static Color get white => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171722);
  static Color get grey1 => _isDark ? const Color(0xFFE4E4EF) : const Color(0xFF2E2E3D);
  static Color get grey2 => _isDark ? const Color(0xFF9191A4) : const Color(0xFF6B6B7C);
  static Color get grey3 => _isDark ? const Color(0xFF4A4A5E) : const Color(0xFFB9B9C6);

  static Color get navBg => _isDark ? const Color(0xFF1A1A26) : const Color(0xFFFFFFFF);
  static Color get navSelected => const Color(0xFFE8712C);
  static Color get navUnsel => _isDark ? const Color(0xFF5C5C73) : const Color(0xFFAFAFC0);

  // ── Journey palette ───────────────────────────────────────────────────────
  //
  // The two flat tones of the Journey look; its gradients live in
  // [AppGradients]. Deliberately separate from [bg]/[white] rather than
  // replacing them: those are what every existing screen is painted with, and
  // repointing them would reskin the whole app as a side effect. A screen opts
  // into the Journey ground by naming these.

  /// Page background for the Journey surfaces — a hair cooler and lighter than
  /// [bg], which is what gives those screens their airier feel.
  ///
  /// The dark build is not a mirrored light value but a near-black carrying the
  /// same faint violet cast, chosen to sit beside the existing [bg] (#13131A)
  /// without reading as a second, competing black.
  static Color get journeyMist => _isDark ? const Color(0xFF14131B) : const Color(0xFFF8F7FC);

  /// Heading text on [journeyMist]. Slightly softer than pure black in light
  /// mode, and slightly off-white in dark, so a large title doesn't harden into
  /// a slab of maximum contrast against the tinted ground.
  static Color get journeyInk => _isDark ? const Color(0xFFF5F3FB) : const Color(0xFF22212A);
}
