import 'package:flutter/material.dart';

/// Blue-light "eye care" filter shared by every reader (EPUB, PDF, CBZ).
///
/// The filter is a single warm wash painted *over* the page — the same trick
/// the PDF reader already uses for its sepia mode — so it needs no per-format
/// rendering support. [level] is 0.0 (off) … 1.0 (warmest); returns null when
/// off so callers can skip painting the layer entirely.
///
/// [isDarkPage] picks *which* warm colour is blended in: alpha-blending a
/// light tan over a dark page always lightens it towards that tan, no matter
/// how low the alpha — visibly breaking dark mode instead of just warming it.
/// Using a dark warm brown on dark pages keeps the result dark; the light tan
/// is reserved for light pages. Either way only the hue shifts, not how dark
/// or light the page reads. Capped well below opaque ([_maxAlpha]) so even
/// the warmest setting stays a faint cast rather than a visible dye.
Color? readerEyeCareColor(double level, {required bool isDarkPage}) {
  if (level <= 0.0) return null;
  final tint = isDarkPage ? readerEyeCareTintDark : readerEyeCareTintLight;
  return tint.withValues(alpha: (level.clamp(0.0, 1.0)) * _maxAlpha);
}

/// Blends [base] toward the eye-care hue in proportion to [level] — used to
/// carry the same warm cast into the reader chrome (the top/bottom bars' icon
/// wells and hairlines) so they don't sit there as a stray neutral black/white
/// while the page itself is tinted. [isDarkPage] picks the light/dark variant
/// the same way [readerEyeCareColor] does, so a dark bar doesn't lighten
/// either. [strength] caps how far even a full-level filter can pull the mix,
/// so the wells stay legible against their own scrim.
Color eyeCareTint(Color base, double level, {required bool isDarkPage, double strength = 0.3}) {
  if (level <= 0.0) return base;
  final tint = isDarkPage ? readerEyeCareTintDark : readerEyeCareTintLight;
  return Color.lerp(base, tint, level.clamp(0.0, 1.0) * strength) ?? base;
}

/// The filter's hue on a light page — a muted warm tan/khaki, closer to aged
/// paper than a bright amber, so it reads as gentle eye comfort rather than a
/// colour cast.
const Color readerEyeCareTintLight = Color(0xFFD6A36B);

/// The filter's hue on a dark page — a dark warm brown rather than the light
/// tan above, so blending it in shifts the hue without lightening the page.
const Color readerEyeCareTintDark = Color(0xFF3D2A18);

// Capped low: even at the warmest setting the wash should read as a faint
// cast, barely-there rather than a visible dye — a higher cap made the page
// look distinctly tan/orange, much stronger than intended.
const double _maxAlpha = 0.14;
