import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';

/// Firebase Analytics wrapper — same singleton pattern as [AppTheme] and
/// [AppLocale].
///
/// `firebase_options.dart` only carries Android and iOS config and throws
/// `UnsupportedError` for every other target — including web, which is how
/// `.claude/launch.json` previews the app. So [init] no-ops off mobile and a
/// failed init leaves every log method a no-op instead of throwing, letting
/// the same `main()` run on every target.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  List<NavigatorObserver> _observers = const <NavigatorObserver>[];

  /// True once Firebase actually came up. Callers don't need to check it —
  /// the log methods no-op on their own — it's here for debugging.
  bool get isEnabled => _analytics != null;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Emits `screen_view` as routes are pushed and popped. Built once in [init]
  /// rather than per call, because `MaterialApp` rebuilds on every theme and
  /// language change and a fresh observer each time would re-register listeners.
  /// Empty off mobile so `navigatorObservers` can take it unconditionally.
  List<NavigatorObserver> get navigatorObservers => _observers;

  Future<void> init() async {
    if (!_isSupportedPlatform) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final analytics = FirebaseAnalytics.instance;
      _analytics = analytics;
      _observers = <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: analytics),
      ];
    } catch (error, stack) {
      // A dead analytics pipeline must never keep the app from booting.
      debugPrint('AnalyticsService.init failed: $error\n$stack');
    }
  }

  /// Escape hatch for events without a dedicated method below.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  /// Standard Firebase event names are used throughout so the Analytics
  /// console reports on them without extra configuration.
  Future<void> logSearch(String term) async {
    await _analytics?.logSearch(searchTerm: term);
  }

  Future<void> logSelectBook(
      {required String id, required String title}) async {
    await _analytics?.logSelectContent(contentType: 'book', itemId: id);
    await logEvent('book_selected',
        parameters: {'book_id': id, 'title': title});
  }

  Future<void> logBookOpened(
      {required String id, required String format}) async {
    await logEvent('book_opened',
        parameters: {'book_id': id, 'format': format});
  }

  Future<void> logPurchase({
    required String bookId,
    required double value,
    required String currency,
  }) async {
    await _analytics?.logPurchase(
        currency: currency, value: value, parameters: {'book_id': bookId});
  }

  Future<void> logLogin() async => _analytics?.logLogin(loginMethod: 'phone');

  /// Lets Analytics segment every report by UI language, which the device
  /// locale wouldn't capture — the app's language is picked in Settings and
  /// often differs from it.
  Future<void> setLanguage(String languageCode) async {
    await _analytics?.setUserProperty(
        name: 'app_language', value: languageCode);
  }
}
