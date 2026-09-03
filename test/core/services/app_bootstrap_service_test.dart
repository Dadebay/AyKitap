// Regression cover for AppBootstrapService's ordering, parallelism, error
// isolation and idempotency guarantees. Every dependency is injected —
// none of these tests touch a real SharedPreferences read, network call or
// platform channel.
import 'dart:async';

import 'package:aykitap/core/services/app_bootstrap_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds an [AppBootstrapService] with every seam defaulted to an instant
/// no-op — a test overrides only the ones it actually cares about, instead
/// of every branch it doesn't falling through to the real singleton (which
/// would hit a platform channel with nothing registered to answer it).
AppBootstrapService _bootstrap({
  Future<void> Function()? loadTheme,
  Future<void> Function()? initializeDateFormattingData,
  Future<void> Function()? loadLocale,
  Future<void> Function()? initAnalytics,
  Future<void> Function(String languageCode)? setAnalyticsLanguage,
  bool Function()? isAnalyticsEnabled,
  Future<void> Function()? initFirebaseMessaging,
  Future<void> Function()? initOneSignalAndLogin,
  Future<void> Function()? initRevenueCatAndLogin,
  Future<void> Function()? loadLastReadBook,
  Future<void> Function()? loadStreak,
  Future<void> Function()? syncHomeScreenWidgets,
  Future<void> Function()? primeDeviceFingerprint,
  void Function()? initAppActivity,
  void Function(String context, Object error, StackTrace stackTrace)? onError,
}) =>
    AppBootstrapService(
      loadTheme: loadTheme ?? _noop,
      initializeDateFormattingData: initializeDateFormattingData ?? _noop,
      loadLocale: loadLocale ?? _noop,
      initAnalytics: initAnalytics ?? _noop,
      setAnalyticsLanguage: setAnalyticsLanguage ?? (_) async {},
      isAnalyticsEnabled: isAnalyticsEnabled ?? (() => true),
      initFirebaseMessaging: initFirebaseMessaging ?? _noop,
      initOneSignalAndLogin: initOneSignalAndLogin ?? _noop,
      initRevenueCatAndLogin: initRevenueCatAndLogin ?? _noop,
      loadLastReadBook: loadLastReadBook ?? _noop,
      loadStreak: loadStreak ?? _noop,
      syncHomeScreenWidgets: syncHomeScreenWidgets ?? _noop,
      primeDeviceFingerprint: primeDeviceFingerprint ?? _noop,
      initAppActivity: initAppActivity ?? (() {}),
      // Surfaces an unexpectedly-swallowed error as a test failure instead
      // of silently passing — a test that expects a failure overrides this
      // itself to assert on it.
      onError: onError ??
          (context, error, stackTrace) =>
              fail('unexpected failure in "$context": $error'),
    );

Future<void> _noop() async {}

void main() {
  group('runBeforeFirstFrame', () {
    test('date-formatting data loads before locale is applied', () async {
      final order = <String>[];
      final service = _bootstrap(
        loadTheme: () async => order.add('theme'),
        initializeDateFormattingData: () async {
          // A real delay, not just a synchronous return — proves loadLocale
          // genuinely waits for this to *resolve*, not just for it to be
          // called.
          await Future<void>.delayed(const Duration(milliseconds: 5));
          order.add('date-formatting');
        },
        loadLocale: () async => order.add('locale'),
      );

      await service.runBeforeFirstFrame();

      final dateFormattingIndex = order.indexOf('date-formatting');
      final localeIndex = order.indexOf('locale');
      expect(dateFormattingIndex, greaterThanOrEqualTo(0));
      expect(localeIndex, greaterThan(dateFormattingIndex));
    });

    test('theme and the locale chain run in parallel, not one after another',
        () async {
      final themeStarted = Completer<void>();
      final dateFormattingStarted = Completer<void>();
      final release = Completer<void>();

      final service = _bootstrap(
        loadTheme: () async {
          themeStarted.complete();
          await release.future;
        },
        initializeDateFormattingData: () async {
          dateFormattingStarted.complete();
          await release.future;
        },
      );

      final future = service.runBeforeFirstFrame();
      // Both branches must have *started* without either having been
      // awaited to completion first — a sequential implementation would
      // leave the second Completer unfired at this point.
      await Future.wait([themeStarted.future, dateFormattingStarted.future])
          .timeout(const Duration(seconds: 1));

      release.complete();
      await future;
    });
  });

  group('runAfterFirstFrame', () {
    test('a slow analytics init does not block other branches', () async {
      final analyticsRelease = Completer<void>();
      var lastReadLoaded = false;

      final service = _bootstrap(
        initAnalytics: () => analyticsRelease.future,
        loadLastReadBook: () async => lastReadLoaded = true,
      );

      final future = service.runAfterFirstFrame();
      // Give every other branch a chance to run to completion while
      // analytics is still deliberately stuck.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(lastReadLoaded, isTrue);

      analyticsRelease.complete();
      await future;
    });

    test('analytics throwing does not crash the bootstrap', () async {
      final service = _bootstrap(
        initAnalytics: () async => throw Exception('firebase unreachable'),
        onError: (_, __, ___) {}, // this test's whole point is the failure
      );

      await expectLater(service.runAfterFirstFrame(), completes);
    });

    test('widget sync is not called until both stores have loaded', () async {
      final lastReadRelease = Completer<void>();
      final streakRelease = Completer<void>();
      var syncCalled = false;

      final service = _bootstrap(
        loadLastReadBook: () => lastReadRelease.future,
        loadStreak: () => streakRelease.future,
        syncHomeScreenWidgets: () async => syncCalled = true,
      );

      final future = service.runAfterFirstFrame();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalled, isFalse);

      lastReadRelease.complete();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(syncCalled, isFalse, reason: 'streak has not resolved yet');

      streakRelease.complete();
      await future;
      expect(syncCalled, isTrue);
    });

    test('widget sync runs exactly once after both stores resolve', () async {
      var syncCount = 0;
      final service = _bootstrap(
        syncHomeScreenWidgets: () async => syncCount++,
      );

      await service.runAfterFirstFrame();

      expect(syncCount, 1);
    });

    test('widget sync failing still lets other branches complete', () async {
      var revenueCatCalled = false;
      final service = _bootstrap(
        syncHomeScreenWidgets: () async =>
            throw Exception('home_widget missing'),
        initRevenueCatAndLogin: () async => revenueCatCalled = true,
        onError: (_, __, ___) {}, // this test's whole point is the failure
      );

      await expectLater(service.runAfterFirstFrame(), completes);
      expect(revenueCatCalled, isTrue);
    });

    test('reports isolated failures through onError without rethrowing',
        () async {
      final reported = <String>[];
      final service = _bootstrap(
        initAnalytics: () async => throw Exception('boom'),
        onError: (context, error, stackTrace) => reported.add(context),
      );

      await service.runAfterFirstFrame();

      expect(reported, contains('analytics+fcm'));
    });

    test('calling it twice does not start critical services twice', () async {
      var analyticsCount = 0;
      var revenueCatCount = 0;
      final service = _bootstrap(
        initAnalytics: () async => analyticsCount++,
        initRevenueCatAndLogin: () async => revenueCatCount++,
      );

      await service.runAfterFirstFrame();
      await service.runAfterFirstFrame();

      expect(analyticsCount, 1);
      expect(revenueCatCount, 1);
    });

    test('firebase messaging only starts once analytics is enabled', () async {
      var fcmCalled = false;
      final service = _bootstrap(
        isAnalyticsEnabled: () => false,
        initFirebaseMessaging: () async => fcmCalled = true,
      );

      await service.runAfterFirstFrame();

      expect(fcmCalled, isFalse);
    });

    test('onesignal still runs when analytics fails', () async {
      var oneSignalCalled = false;
      final service = _bootstrap(
        initAnalytics: () async => throw Exception('firebase unreachable'),
        initOneSignalAndLogin: () async => oneSignalCalled = true,
        onError: (_, __, ___) {}, // this test's whole point is the failure
      );

      await service.runAfterFirstFrame();

      expect(oneSignalCalled, isTrue);
    });
  });

  test('push services are not an awaited dependency of the pre-frame phase',
      () async {
    // Neither seam is ever completed — if runBeforeFirstFrame accidentally
    // awaited either, this test would hang and time out.
    final neverCompletes = Completer<void>().future;
    final service = _bootstrap(
      initFirebaseMessaging: () => neverCompletes,
      initOneSignalAndLogin: () => neverCompletes,
    );

    await expectLater(
      service.runBeforeFirstFrame(),
      completes,
    );
  });
}
