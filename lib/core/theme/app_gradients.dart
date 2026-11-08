import 'package:flutter/widgets.dart';
import 'theme_controller.dart';

/// Gradients reused verbatim across multiple screens. Anything used only
/// once (e.g. a single collection card's own colors, or a page-specific
/// onboarding illustration) stays where it's defined — it isn't a shared
/// token, just a one-off value that happens to be a gradient.
abstract final class AppGradients {
  static bool get _isDark => AppTheme.instance.isDark;

  /// Auth screen icon badges (phone/name entry, OTP) and the BookTok
  /// collection card on Home — the coral → purple pair used in 6+ places.
  static const LinearGradient coralPurple = LinearGradient(
    colors: [Color(0xFFF77E68), Color(0xFFB44BE8)],
  );

  /// Own-books "spine" placeholder cover background — PDF vs EPUB vs CBZ —
  /// reused identically by [LibraryScreen] and `OfflineLibraryScreen`.
  static const LinearGradient pdfSpine = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6B3B3B), Color(0xFF2E1919)],
  );
  static const LinearGradient epubSpine = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3B4A6B), Color(0xFF191F2E)],
  );
  static const LinearGradient cbzSpine = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6B4B2E), Color(0xFF2E2115)],
  );

  // ── Journey palette ───────────────────────────────────────────────────────
  //
  // One warm-to-violet family (orange → rose → purple) shared by the badges,
  // cards and accents that make up the "Journey" look. Every gradient below
  // comes in a light and a dark build and is handed out through a getter, so a
  // caller writes `AppGradients.journeyPrimary` once and gets whichever build
  // suits the current theme — the same contract [AppColors] already has.
  //
  // The dark builds are NOT the light ones reused. These hues are the bright
  // end of the spectrum, and at full strength on the near-black app background
  // they glare and bloom rather than read as colour. Each dark stop therefore
  // keeps its hue but drops luminance and a little saturation — enough to sit
  // calmly on #13131A while staying unmistakably the same colour. The pastel
  // set ([journeySoft]) goes further: pastels are defined by being nearly
  // white, so on a dark screen they can only ever be glare. Its dark build is
  // re-cast as deep, tinted surfaces in the same three hues, which is what the
  // pastel is *for* — a soft ground a badge or card sits on.
  //
  // Raw stop lists are exposed alongside each gradient so a caller that needs
  // different geometry (a ShaderMask, a SweepGradient, a single stop for a
  // border) can reach for the colours without re-typing the hex values or
  // inventing a near-miss shade of its own.

  /// Signature orange → rose → violet. The primary Journey accent: the one
  /// used for a primary action, a highlighted badge, a featured card.
  static List<Color> get journeyPrimaryColors => _isDark
      ? const [Color(0xFFE8862F), Color(0xFFE64C6C), Color(0xFF7B3FE0)]
      : const [Color(0xFFFF9A3D), Color(0xFFFF5C7D), Color(0xFF8D4DFF)];

  static LinearGradient get journeyPrimary => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: journeyPrimaryColors,
      );

  /// The pastel counterpart of [journeyPrimary] — a quiet tinted ground rather
  /// than an accent, for badge fills and card backgrounds that shouldn't
  /// compete with their own content.
  static List<Color> get journeySoftColors => _isDark
      ? const [Color(0xFF342A24), Color(0xFF33242C), Color(0xFF2A2438)]
      : const [Color(0xFFFFE6D5), Color(0xFFFFD8E4), Color(0xFFE8D9FF)];

  static LinearGradient get journeySoft => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: journeySoftColors,
      );

  /// Rose → violet, the two-stop cut of the family. Narrower and cooler than
  /// [journeyPrimary]; used where a full three-stop sweep is too busy for the
  /// space, e.g. a thin accent on a single row.
  static List<Color> get journeyRoseVioletColors => _isDark
      ? const [Color(0xFFE85B77), Color(0xFF9C3FCC)]
      : const [Color(0xFFFF6A88), Color(0xFFB34BEA)];

  static LinearGradient get journeyRoseViolet => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: journeyRoseVioletColors,
      );

  /// Amber → coral, the warm cut. No violet in it at all, so it reads as
  /// warmth rather than as the full Journey sweep — streaks, rewards, anything
  /// that should feel sunlit.
  static List<Color> get journeySunsetColors => _isDark
      ? const [Color(0xFFE89C3C), Color(0xFFE64E5D)]
      : const [Color(0xFFFFB34D), Color(0xFFFF5F6D)];

  static LinearGradient get journeySunset => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: journeySunsetColors,
      );
}
