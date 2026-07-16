import 'package:flutter/widgets.dart';

/// Gradients reused verbatim across multiple screens. Anything used only
/// once (e.g. a single collection card's own colors, or a page-specific
/// onboarding illustration) stays where it's defined — it isn't a shared
/// token, just a one-off value that happens to be a gradient.
abstract final class AppGradients {
  /// Auth screen icon badges (phone/name entry, OTP) and the BookTok
  /// collection card on Home — the coral → purple pair used in 6+ places.
  static const LinearGradient coralPurple = LinearGradient(
    colors: [Color(0xFFF77E68), Color(0xFFB44BE8)],
  );

  /// Own-books "spine" placeholder cover background — PDF vs EPUB — reused
  /// identically by [LibraryScreen] and `OfflineLibraryScreen`.
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
}
