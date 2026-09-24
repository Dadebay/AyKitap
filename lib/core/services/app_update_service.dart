import 'dart:developer';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Debug-only trace of the update check, in colour so it stands out in a
/// noisy `flutter run` console.
///
/// Every step prints a line, including the ones that end in "no sheet" —
/// when the sheet doesn't appear, the useful information is *which* step
/// decided that, and a silent path leaves that as guesswork. Stripped from
/// release builds by the `kDebugMode` check.
void updateDebugLog(String message, {bool ok = false, bool bad = false}) {
  if (!kDebugMode) return;
  const reset = '\x1B[0m';
  final colour = ok
      ? '\x1B[32m' // green — the sheet is on its way
      : bad
          ? '\x1B[31m' // red — nothing will be shown
          : '\x1B[36m'; // cyan — a step along the way
  // ignore: avoid_print
  print('$colour[UPDATE] $message$reset');
}

/// A newer build of the app, as the store reports it.
class StoreRelease {
  const StoreRelease({
    required this.version,
    required this.installedVersion,
    required this.storeUrl,
  });

  /// The version string the store is serving, e.g. `1.2.1`.
  final String version;
  final String installedVersion;

  /// Where to send the reader to get it.
  final Uri storeUrl;
}

/// Asks the App Store / Google Play whether a newer build than the installed
/// one is published, so the app can offer the update itself instead of
/// waiting for the reader to notice.
///
/// Neither store is asked through [DioClient]: these are other people's
/// hosts, and sending this app's `Authorization` header and `Accept-Language`
/// to them would be both pointless and careless. A short timeout, because
/// nothing in the app waits on the answer — a check that doesn't come back is
/// simply a check that didn't happen.
///
/// Both lookups can fail for reasons that have nothing to do with the app:
/// on some networks these hosts are unreachable (the RevenueCat logs from
/// Turkmenistan show `api.revenuecat.com` resolving to `127.0.0.1`), and
/// Play has no official version API at all — the number is read out of the
/// store page, which Google may re-arrange at any time. Every failure path
/// therefore returns null, which means "don't bother the reader", never an
/// error on screen.
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  /// Debug-only pretend-installed version, for trying the update sheet
  /// without shipping a build the store is actually newer than.
  ///
  /// Set it to something below what the store serves (e.g. `'1.0.0'` while
  /// the store has 1.1.5) and the check behaves exactly as it would on an
  /// out-of-date install — same sheet, same "Soňra" memory, same store link.
  /// Null in normal use, and ignored outside debug mode no matter what it
  /// holds, so a value left behind here can never reach a release build.
  ///
  /// Two things to know while testing: the version line at the bottom of
  /// Settings keeps reporting the *real* build (it reads the bundle, not
  /// this), and "Soňra" still remembers the declined version — so to see the
  /// sheet a second time, clear the app's data or reinstall.
  // Nullable on purpose: null is the off switch. The lint only fires because
  // a test value happens to be set right now.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? debugInstalledVersionOverride = '1.0.0';

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    // Play serves a different page to an unrecognised client; iTunes does
    // not care. A desktop UA is what the page-scrape below is written for.
    headers: const {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    },
  ));

  /// The store's version, or null when there is nothing to offer — already
  /// up to date, an unsupported platform, or a lookup that failed.
  Future<StoreRelease?> check() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      updateDebugLog('Platform is not iOS/Android — no check', bad: true);
      return null;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      final overridden = kDebugMode && debugInstalledVersionOverride != null;
      final installed =
          overridden ? debugInstalledVersionOverride! : info.version;
      updateDebugLog('Package: ${info.packageName}');
      updateDebugLog(
        overridden
            ? 'Installed: $installed (FAKE — real build is '
                '${info.version}+${info.buildNumber})'
            : 'Installed: $installed+${info.buildNumber}',
      );
      updateDebugLog(
          'Asking ${Platform.isIOS ? "App Store" : "Google Play"}...');
      final release = Platform.isIOS
          ? await _appStore(info.packageName)
          : await _playStore(info.packageName);
      if (release == null) {
        updateDebugLog(
          'Store returned no version (app not published there, network '
          'blocked, or the page layout changed) — no sheet',
          bad: true,
        );
        return null;
      }
      updateDebugLog('Store version: ${release.$1}  →  ${release.$2}');
      if (!isNewerVersion(release.$1, installed)) {
        updateDebugLog(
          'Store ${release.$1} is not newer than installed $installed — '
          'no sheet',
          bad: true,
        );
        return null;
      }
      updateDebugLog(
        'Update available: $installed → ${release.$1}',
        ok: true,
      );
      return StoreRelease(
        version: release.$1,
        installedVersion: installed,
        storeUrl: release.$2,
      );
    } catch (e) {
      log('ℹ️ Update check skipped: $e');
      updateDebugLog('Check threw: $e — no sheet', bad: true);
      return null;
    }
  }

  /// iTunes Lookup — Apple's own public endpoint, so this one is exact.
  ///
  /// It answers per storefront and defaults to the US one, where an app that
  /// only ships to a few countries does not exist; an empty result there is
  /// not "no update", so the app's own regions are tried before giving up.
  Future<(String, Uri)?> _appStore(String bundleId) async {
    for (final country in const ['tm', 'tr', 'ru', 'us']) {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://itunes.apple.com/lookup',
        queryParameters: {'bundleId': bundleId, 'country': country},
        options: Options(responseType: ResponseType.json),
      );
      final results = response.data?['results'] as List?;
      if (results == null || results.isEmpty) continue;
      final first = results.first as Map<String, dynamic>;
      final version = first['version'] as String?;
      if (version == null || version.isEmpty) continue;
      final url = first['trackViewUrl'] as String?;
      return (
        version,
        Uri.parse(url ?? 'https://apps.apple.com/app/id${first['trackId']}'),
      );
    }
    return null;
  }

  /// Play has no public version API, so this reads the store page.
  ///
  /// The old `itemprop="softwareVersion"` markup is long gone; the number now
  /// sits in one of the page's inline JSON blobs, in a `[[["1.2.1"]]]` shape.
  /// That is a Google implementation detail and will break without warning —
  /// which is survivable, because failing to find it just skips the check.
  Future<(String, Uri)?> _playStore(String packageId) async {
    final pageUrl = 'https://play.google.com/store/apps/details?id=$packageId';
    final response = await _dio.get<String>(
      pageUrl,
      queryParameters: {'hl': 'en', 'gl': 'US'},
      options: Options(responseType: ResponseType.plain),
    );
    final body = response.data;
    if (body == null || body.isEmpty) return null;
    final match = RegExp(r'\[\[\["(\d+(?:\.\d+)+)"\]\]').firstMatch(body);
    final version = match?.group(1);
    if (version == null) return null;
    return (version, Uri.parse(pageUrl));
  }
}

/// Whether [store] is a later release than [installed].
///
/// Compares dot-separated numbers left to right, so `1.10.0` is correctly
/// newer than `1.9.9` — the string comparison that keeps getting written
/// instead says the opposite. A missing part counts as 0, so `1.2` and
/// `1.2.0` are the same release. Anything non-numeric in a part (`1.2.0-rc1`)
/// is read up to its first non-digit; a part with no digits at all makes the
/// whole comparison return false, because guessing at an unknown format is
/// how a reader ends up nagged to install what they already have.
@visibleForTesting
bool isNewerVersion(String store, String installed) {
  final a = _parts(store);
  final b = _parts(installed);
  if (a == null || b == null) return false;
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final left = i < a.length ? a[i] : 0;
    final right = i < b.length ? b[i] : 0;
    if (left != right) return left > right;
  }
  return false;
}

List<int>? _parts(String version) {
  final trimmed = version.trim();
  if (trimmed.isEmpty) return null;
  final parts = <int>[];
  for (final piece in trimmed.split('.')) {
    final digits = RegExp(r'^\d+').firstMatch(piece)?.group(0);
    if (digits == null) return null;
    parts.add(int.parse(digits));
  }
  return parts.isEmpty ? null : parts;
}
