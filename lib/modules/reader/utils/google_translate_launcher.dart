import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_locale.dart';

/// Sends the complete selected passage to Google Translate. Android tries
/// the installed app first; other platforms and missing apps use the web UI.
abstract final class GoogleTranslateLauncher {
  static const _channel = MethodChannel('com.aykitap.aykitap/translate');

  static Uri urlFor(String text, AppLanguageCode target) => Uri.https(
        'translate.google.com',
        '/',
        {
          'sl': 'auto',
          'tl': target.name,
          'text': text.trim(),
          'op': 'translate'
        },
      );

  static Future<bool> open(String selectedText) async {
    final text = selectedText.trim();
    if (text.isEmpty) return false;
    final url = urlFor(text, AppLocale.instance.current);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        if (await _channel.invokeMethod<bool>('openSelectedText', text) ==
            true) {
          return true;
        }
      } on PlatformException {
        // Google Translate may be absent or not accept a text intent.
      } on MissingPluginException {
        // Flutter tests and older app builds can still use the web fallback.
      }
      try {
        if (await _channel.invokeMethod<bool>('openInChrome', url.toString()) ==
            true) {
          return true;
        }
      } on PlatformException {
        // Chrome is unavailable; let Android choose another browser below.
      } on MissingPluginException {
        // Older app builds still use the normal external-browser fallback.
      }
    }

    try {
      return await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
