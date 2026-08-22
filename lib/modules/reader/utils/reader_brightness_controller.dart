import 'dart:developer';

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
class ReaderBrightnessController {
  Future<void> apply(double value) async {
    try {
      await ScreenBrightness()
          .setApplicationScreenBrightness(value.clamp(0.0, 1.0));
    } catch (e) {
      log('❌ Brightness error: $e');
    }
  }

  Future<void> release() async {
    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      log('❌ Brightness reset error: $e');
    }
  }
}
