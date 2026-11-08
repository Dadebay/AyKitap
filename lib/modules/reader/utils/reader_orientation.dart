import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/layout/app_orientation_policy.dart';

/// Where the reader's "ýatyk okamak" choice is kept. App-wide rather than
/// per-book, and shared by all three readers, so turning it on in one does
/// not leave the next book opening the other way round.
const readerLandscapePrefKey = 'reader_landscape';

/// Landscape reading, shared by every reader (EPUB, PDF, CBZ).
///
/// A compact window (a phone) is locked to portrait everywhere except while
/// a reader is open — the app shell (Home, Library, Profile, ...) has no
/// landscape layout, but a reader is just a page of content: turning the
/// phone sideways gives a wider column for a PDF's fixed-width page or a
/// CBZ's double-page spread, which is why readers normally allow it. A
/// medium/expanded window (a tablet, a foldable, a desktop) was never locked
/// in the first place — see [AppOrientationPolicy], which is what actually
/// decides and applies the allowed orientation set; these functions are
/// just the reader-open/reader-closed signal into it, kept as the same pair
/// of names every reader screen's initState/dispose already called before
/// the policy existed, so none of them had to change.
///
/// The saved preference is read here rather than passed in, so a reader that
/// has no settings row for it (PDF, CBZ) still opens the way the reader last
/// asked for. Deliberately not awaited by its callers — the orientation
/// settles a frame or two into the book rather than holding up its open.
///
/// On iOS this is additionally gated by `UISupportedInterfaceOrientations` in
/// Info.plist: iOS only honours orientations listed there, so the landscape
/// entries must stay in that list for this to have any effect.
Future<void> enableReaderLandscape() async {
  final prefs = await SharedPreferences.getInstance();
  AppOrientationPolicy.instance.setReaderActive(
    true,
    forcesLandscape: prefs.getBool(readerLandscapePrefKey) ?? false,
  );
}

/// Tells [AppOrientationPolicy] the reader has closed, restoring whatever
/// orientation lock applies to the rest of the app for the current window.
void restoreAppPortraitLock() {
  AppOrientationPolicy.instance.setReaderActive(false);
}

/// Saves the reader's choice and turns the phone now, rather than at the next
/// book — the setting is changed from inside an open reader, so it has to
/// take effect while that reader is still on screen to be worth anything.
Future<void> setReaderLandscapeReading(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(readerLandscapePrefKey, enabled);
  AppOrientationPolicy.instance.setReaderActive(true, forcesLandscape: enabled);
}
