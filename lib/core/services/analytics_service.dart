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

  /// A stable observer instance handed to `MaterialApp` once, up front —
  /// [init] now runs after the first frame rather than being awaited ahead
  /// of `runApp()` (a Firebase outage must not delay it), so the real
  /// [FirebaseAnalyticsObserver] usually doesn't exist yet at the moment
  /// `MaterialApp` is built. This proxy is a safe no-op until [init]
  /// resolves and calls [_DeferredNavigatorObserver.attach] on it — from
  /// then on, every route push/pop already flowing through this same
  /// object (it's the one actually registered on the Navigator) reaches
  /// the real observer too, with no `MaterialApp` rebuild required to swap
  /// it in.
  final _observerProxy = _DeferredNavigatorObserver();

  /// True once Firebase actually came up. Callers don't need to check it —
  /// the log methods no-op on their own — it's here for debugging.
  bool get isEnabled => _analytics != null;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Emits `screen_view` as routes are pushed and popped. The same list
  /// (wrapping the same proxy instance) on every call, on or off mobile —
  /// see [_observerProxy].
  List<NavigatorObserver> get navigatorObservers => [_observerProxy];

  Future<void> init() async {
    if (!_isSupportedPlatform) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final analytics = FirebaseAnalytics.instance;
      _analytics = analytics;
      _observerProxy.attach(FirebaseAnalyticsObserver(analytics: analytics));
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
      {required String id,
      required String format,
      String source = 'unknown'}) async {
    await logEvent('book_opened',
        parameters: {'book_id': id, 'format': format});
    await logEvent('reader_opened', parameters: {
      'book_id': id,
      'format': format,
      'source': source,
    });
  }

  Future<void> logPaywallViewed({required String source}) => logEvent(
        'paywall_viewed',
        parameters: {'source': source},
      );

  Future<void> logPurchaseStep({
    required String step,
    required String productType,
    required String productId,
    required String source,
    num? value,
  }) {
    return logEvent('purchase_$step', parameters: {
      'product_type': productType,
      'product_id': productId,
      'source': source,
      if (value != null) 'value': value,
    });
  }

  Future<void> logReadingGoalCompleted({
    required int pages,
    required int minutes,
    required int streak,
  }) {
    return logEvent('reading_goal_completed', parameters: {
      'pages': pages,
      'minutes': minutes,
      'streak': streak,
    });
  }

  Future<void> logPurchase({
    required String bookId,
    required double value,
    required String currency,
  }) async {
    await _analytics?.logPurchase(
        currency: currency, value: value, parameters: {'book_id': bookId});
  }

  Future<void> logLogin({String loginMethod = 'phone'}) async =>
      _analytics?.logLogin(loginMethod: loginMethod);

  /// Lets Analytics segment every report by UI language, which the device
  /// locale wouldn't capture — the app's language is picked in Settings and
  /// often differs from it.
  Future<void> setLanguage(String languageCode) async {
    await _analytics?.setUserProperty(
        name: 'app_language', value: languageCode);
  }
}

/// Forwards every call to whatever real [NavigatorObserver] is attached —
/// nothing before [attach], every call after. See
/// [AnalyticsService._observerProxy] for why this exists instead of
/// swapping the observer list on `MaterialApp` directly.
class _DeferredNavigatorObserver extends NavigatorObserver {
  NavigatorObserver? _real;

  void attach(NavigatorObserver real) => _real = real;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _real?.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _real?.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _real?.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _real?.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic>? previousRoute) {
    _real?.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    _real?.didStopUserGesture();
  }
}
