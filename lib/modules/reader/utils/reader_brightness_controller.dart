import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:screen_brightness/screen_brightness.dart';

/// Drives the device screen brightness (TZ §12.4) for whichever reader is
/// open. Shared across the EPUB, PDF and CBZ readers — each owns one
/// instance and calls [apply] on every brightness-slider change and once on
/// open, [release] once on close.
///
/// At full brightness an explicit value is still set rather than releasing
/// control back to the system: doing that at 1.0 used to make the slider's
/// "100%" visibly *dim* the screen, snapping to whatever the OS brightness
/// happened to be instead of showing true full brightness. Control is only
/// handed back via [release], when the reader actually closes.
///
/// ## Why the phone's own brightness slider stopped working in the reader
///
/// That explicit value is a *window* brightness override on Android, and
/// while it is set it outranks the system value. Pulling down the notification
/// panel and dragging the system slider then changes the system setting and
/// nothing else: the screen does not move, so the reader concludes the phone
/// is broken (reported on a Galaxy S25 Ultra and an A41; an Honor handset was
/// unaffected, because some OEM panels write the window value too — which is
/// exactly why this looked device-specific).
///
/// [onExternalChange] is the fix. While a reader is open this watches the
/// system brightness, and when it moves — the panel, a hardware key, adaptive
/// brightness — it reports the new value so the owner can adopt it: apply it
/// as the window value (so the screen actually follows the phone's slider)
/// and save it, the same way it saves a change made with the in-app slider.
class ReaderBrightnessController {
  ReaderBrightnessController({this.onExternalChange});

  /// Called with the phone's new brightness whenever it is changed from
  /// outside the app. Owners should route it into the same setter their own
  /// slider uses, so applying and persisting stay in one place.
  final void Function(double value)? onExternalChange;

  StreamSubscription<double>? _systemChanges;
  Timer? _debounce;

  Future<void> apply(double value) async {
    _listenForSystemChanges();
    try {
      await ScreenBrightness()
          .setApplicationScreenBrightness(value.clamp(0.0, 1.0));
    } catch (e) {
      log('❌ Brightness error: $e');
    }
  }

  /// Starts on the first [apply] rather than in the constructor — that is the
  /// moment a reader actually opens, and it keeps the subscription's life
  /// exactly as long as the override it exists to compensate for.
  ///
  /// Android only, and deliberately. iOS has no problem to solve: an
  /// application brightness there *is* `UIScreen.brightness`, the same value
  /// Control Centre writes, so its slider already moves the screen inside the
  /// reader. Worse, screen_brightness_ios only watches the system value while
  /// the app is inactive and then emits once on resume — so listening on iOS
  /// would overwrite the reader's chosen brightness with the phone's every
  /// time the app came back to the foreground.
  void _listenForSystemChanges() {
    if (_systemChanges != null || onExternalChange == null) return;
    if (!Platform.isAndroid) return;
    try {
      _systemChanges =
          ScreenBrightness().onSystemScreenBrightnessChanged.listen((value) {
        // A drag on the panel emits a burst of values; the screen only has to
        // keep up with the end of each gesture, and every forwarded value
        // costs a preferences write.
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 120),
            () => onExternalChange?.call(value.clamp(0.0, 1.0)));
      }, onError: (Object e) => log('❌ Brightness stream error: $e'));
    } catch (e) {
      // A platform without a system-brightness stream simply keeps the old
      // behaviour: the in-app slider still works, the phone's own does not.
      log('❌ Brightness listener error: $e');
    }
  }

  Future<void> release() async {
    _debounce?.cancel();
    _debounce = null;
    await _systemChanges?.cancel();
    _systemChanges = null;
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      log('❌ Brightness reset error: $e');
    }
  }
}
