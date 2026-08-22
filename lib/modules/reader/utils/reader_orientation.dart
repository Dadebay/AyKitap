import 'package:flutter/services.dart';

/// Landscape reading, shared by every reader (EPUB, PDF, CBZ).
///
/// main.dart locks the whole app to [DeviceOrientation.portraitUp] — the app
/// shell (Home, Library, Profile, ...) is designed portrait-only and has no
/// landscape layout. A *reader*, though, is just a page of content: turning
/// the phone sideways gives a wider column for a PDF's fixed-width page or a
/// CBZ's double-page spread, which is why readers normally allow it.
///
/// So these two are a pair, called from a reader screen's initState/dispose
/// exactly like the immersive-mode calls they sit next to: unlock on the way
/// in, restore the app-wide portrait lock on the way out. Restoring on exit is
/// what keeps the rest of the app portrait — without it a reader left in
/// landscape would drop the user back into a sideways Home screen.
///
/// On iOS this is additionally gated by `UISupportedInterfaceOrientations` in
/// Info.plist: iOS only honours orientations listed there, so the landscape
/// entries must stay in that list for this to have any effect.
void enableReaderLandscape() {
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Restores the app-wide portrait lock set in main.dart.
void restoreAppPortraitLock() {
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
}
