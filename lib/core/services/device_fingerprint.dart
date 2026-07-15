import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stable per-install device identifier for the backend's "bir hasap —
/// bir enjam" (one account — one device) check at login (TZ 2.2).
///
/// The login/OTP-verify endpoints don't accept this yet, so nothing sends
/// it anywhere. It's cached here, ready to attach to that request body the
/// moment the backend contract adds a field for it.
class DeviceFingerprint {
  DeviceFingerprint._();

  static const _kFallbackId = 'device_fingerprint_fallback_id';
  static String? _cached;

  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;
    final id = await _resolve();
    _cached = id;
    return id;
  }

  static Future<String> _resolve() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        return _persistedFallback(seed: '${info.vendor}-${info.userAgent}');
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.id; // ANDROID_ID — stable per app install
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.identifierForVendor ?? await _persistedFallback(seed: info.identifierForVendor);
      }
    } catch (_) {
      // Plugin unsupported/failed on this platform — fall back below.
    }
    return _persistedFallback();
  }

  /// Used where there's no stable hardware identifier (web, desktop, or a
  /// plugin failure): generate one once and persist it for future launches.
  static Future<String> _persistedFallback({String? seed}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kFallbackId);
    if (existing != null) return existing;

    final raw = '${seed ?? ''}-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(prefs)}';
    final id = sha256.convert(utf8.encode(raw)).toString();
    await prefs.setString(_kFallbackId, id);
    return id;
  }
}
