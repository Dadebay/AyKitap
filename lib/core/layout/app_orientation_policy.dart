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
  WindowWidthClass _windowWidth = WindowWidthClass.compact;
  List<DeviceOrientation>? _lastApplied;

  /// Call once from a reader screen's `initState` (`true`) and `dispose`
  /// (`false`) — see `reader_orientation.dart`'s `enableReaderLandscape`/
  /// `restoreAppPortraitLock`, which are what actually call this so the three
  /// reader screens didn't have to change.
  void setReaderActive(bool active) {
    _readerActive = active;
    _apply();
  }

  /// Call from [AppOrientationObserver] whenever the window's size class is
  /// (re)read — on first build and every time it changes.
  void updateWindow(WindowSizeClass windowSizeClass) {
    _windowWidth = windowSizeClass.width;
    _apply();
  }

  List<DeviceOrientation> _resolve() {
    if (_windowWidth != WindowWidthClass.compact) {
      // No restriction: an empty list tells the platform to allow whatever
      // orientations it would without Flutter's app ever having asked.
      return const [];
    }
    if (_readerActive) {
      return const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    }
    return const [DeviceOrientation.portraitUp];
  }

  void _apply() {
    final next = _resolve();
    if (_lastApplied != null && listEquals(_lastApplied, next)) return;
    _lastApplied = next;
    SystemChrome.setPreferredOrientations(next);
  }
}
