import '../../../core/layout/app_orientation_policy.dart';

/// Landscape reading, shared by every reader (EPUB, PDF, CBZ).
///
/// A compact window (a phone) is locked to portrait everywhere except while
/// a reader is open — the app shell (Home, Library, Profile, ...) has no
/// landscape layout, but a reader is just a page of content: turning the
/// phone sideways gives a wider column for a PDF's fixed-width page or a
/// CBZ's double-page spread, which is why readers normally allow it. A
/// medium/expanded window (a tablet, a foldable, a desktop) was never locked
/// in the first place — see [AppOrientationPolicy], which is what actually
/// decides and applies the allowed orientation set; these two functions are
/// just the reader-open/reader-closed signal into it, kept as the same pair
/// of names every reader screen's initState/dispose already called before
/// the policy existed, so none of them had to change.
///
/// On iOS this is additionally gated by `UISupportedInterfaceOrientations` in
/// Info.plist: iOS only honours orientations listed there, so the landscape
/// entries must stay in that list for this to have any effect.
void enableReaderLandscape() {
  AppOrientationPolicy.instance.setReaderActive(true);
}

/// Tells [AppOrientationPolicy] the reader has closed, restoring whatever
/// orientation lock applies to the rest of the app for the current window.
void restoreAppPortraitLock() {
  AppOrientationPolicy.instance.setReaderActive(false);
}
