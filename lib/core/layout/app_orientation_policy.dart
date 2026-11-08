import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'window_size_class.dart';

/// The single place that decides which device orientations are allowed, and
/// the only place that calls [SystemChrome.setPreferredOrientations].
///
/// The rule (TZ-independent, just this app's own shape):
///
/// * A compact window (a phone) is portrait-only everywhere *except* while a
///   reader is open, where landscape is also allowed — turning the phone
///   sideways gives a PDF's fixed-width page or a CBZ spread a wider column.
///   The rest of the shell (Home, Library, Profile, Search, ...) has no
///   landscape layout and stays locked.
/// * A medium/expanded window (a tablet, a foldable opened flat or in book
///   posture, a desktop) is never orientation-locked: the window itself
///   already dictates the usable shape, and fighting it by forcing
///   `portraitUp` on a wide window is what makes a foldable's outer *and*
///   inner screens feel broken.
///
/// [instance] is process-lifetime and stateless between calls except for
/// [_lastApplied], which exists purely so redundant
/// `setPreferredOrientations` calls are skipped — the platform channel round
/// trip is cheap once, but every rebuild re-deciding "still portrait-only"
/// and re-sending it is the kind of chatter that shows up as jank on a
/// foldable that's mid-hinge-animation and rebuilding every frame.
class AppOrientationPolicy {
  AppOrientationPolicy._();
  static final instance = AppOrientationPolicy._();

  bool _readerActive = false;
  bool _readerForcesLandscape = false;
  WindowWidthClass _windowWidth = WindowWidthClass.compact;
  List<DeviceOrientation>? _lastApplied;

  /// Call once from a reader screen's `initState` (`true`) and `dispose`
  /// (`false`) — see `reader_orientation.dart`'s `enableReaderLandscape`/
  /// `restoreAppPortraitLock`, which are what actually call this so the three
  /// reader screens didn't have to change.
  ///
  /// [forcesLandscape] is the reader's own "ýatyk okamak" setting. Allowing
  /// landscape is not the same as getting it: a phone with the system's
  /// rotation lock switched on never leaves portrait however it is held, so a
  /// reader who wants a wide page has no way to ask for one. Dropping
  /// portrait from the allowed set is that way — Flutter's preferred
  /// orientations outrank the system lock.
  void setReaderActive(bool active, {bool forcesLandscape = false}) {
    _readerActive = active;
    _readerForcesLandscape = forcesLandscape;
    _apply();
  }

  /// Call from [AppOrientationObserver] whenever the window's size class is
  /// (re)read — on first build and every time it changes.
  void updateWindow(WindowSizeClass windowSizeClass) {
    _windowWidth = windowSizeClass.width;
    _apply();
  }

  void _apply() {
    final next = resolveAllowedOrientations(
      windowWidth: _windowWidth,
      readerActive: _readerActive,
      readerForcesLandscape: _readerForcesLandscape,
    );
    if (_lastApplied != null && listEquals(_lastApplied, next)) return;
    _lastApplied = next;
    SystemChrome.setPreferredOrientations(next);
  }
}

/// The orientation set [AppOrientationPolicy] applies for a given state —
/// pulled out as a pure function so the rule can be read, and tested, without
/// a platform channel.
@visibleForTesting
List<DeviceOrientation> resolveAllowedOrientations({
  required WindowWidthClass windowWidth,
  required bool readerActive,
  required bool readerForcesLandscape,
}) {
  if (readerActive && readerForcesLandscape) {
    // Decided *before* the width class, and that order is the whole point.
    // Turning a phone sideways widens the window past the compact
    // breakpoint, so a rule that checked width first would see a medium /
    // expanded window the instant the phone obeyed, lift the restriction,
    // let the device fall back to portrait, see compact again and force
    // landscape once more — the phone flipping back and forth forever
    // instead of settling. The reader asked to read sideways; that answer
    // can't depend on a width that reading sideways is what produced.
    //
    // Portrait is left out on purpose. Keeping it would only *permit*
    // landscape, which a phone with rotation lock on never takes.
    return const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
  }
  if (windowWidth != WindowWidthClass.compact) {
    // No restriction: an empty list tells the platform to allow whatever
    // orientations it would without Flutter's app ever having asked. A wide
    // window is already whatever shape its owner made it — unless the reader
    // explicitly asked for landscape above.
    return const [];
  }
  if (readerActive) {
    return const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
  }
  return const [DeviceOrientation.portraitUp];
}
