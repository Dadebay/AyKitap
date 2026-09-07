import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../localization/app_locale.dart';
import '../network/api_config.dart';
import '../theme/theme_controller.dart';
import 'analytics_service.dart';
import 'app_activity_service.dart';
import 'device_fingerprint.dart';
import 'firebase_messaging_service.dart';
import 'home_screen_widget_service.dart';
import 'last_read_book_store.dart';
import 'onesignal_service.dart';
import 'purchase_mode_service.dart';
import 'revenue_cat_service.dart';
import 'streak_service.dart';

/// Orchestrates every startup task `main()` used to run inline, split into
/// two phases:
///
/// - [runBeforeFirstFrame] — theme and locale, the only two things a user
///   would actually *see* go wrong (a flash of the wrong theme, or a frame
///   in the wrong language) if they weren't ready before `runApp()`.
/// - [runAfterFirstFrame] — everything else: analytics, push (FCM +
///   OneSignal), RevenueCat, the reader's home-screen widgets, the device
///   fingerprint, foreground-time tracking. None of it is visible on the
///   first frame, and a slow or failing network call in any one of them
///   must not hold up the others or the app itself.
///
/// Every constructor parameter defaults to the real call it stands in for
/// — tests override just the ones they need to control timing or failure
/// for, without having to fake the underlying singletons (most of which
/// have no DI seam of their own).
class AppBootstrapService {
  AppBootstrapService({
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
    void Function()? initPurchaseMode,
    void Function(String context, Object error, StackTrace stackTrace)? onError,
  })  : _loadTheme = loadTheme ?? (() => AppTheme.instance.load()),
        _initializeDateFormattingData =
            initializeDateFormattingData ?? initializeDateFormatting,
        _loadLocale = loadLocale ?? (() => AppLocale.instance.load()),
        _initAnalytics =
            initAnalytics ?? (() => AnalyticsService.instance.init()),
        _setAnalyticsLanguage = setAnalyticsLanguage ??
            ((lang) => AnalyticsService.instance.setLanguage(lang)),
        _isAnalyticsEnabled =
            isAnalyticsEnabled ?? (() => AnalyticsService.instance.isEnabled),
        _initFirebaseMessaging = initFirebaseMessaging ??
            (() => FirebaseMessagingService.instance.init()),
        _initOneSignalAndLogin = initOneSignalAndLogin ??
            (() => OneSignalService.instance
                .initialize()
                .then((_) => OneSignalService.instance.loginCurrentUser())),
        _initRevenueCatAndLogin = initRevenueCatAndLogin ??
            (() => RevenueCatService.instance
                .init()
                .then((_) => RevenueCatService.instance.loginCurrentUser())),
        _loadLastReadBook =
            loadLastReadBook ?? (() => LastReadBookStore.instance.load()),
        _loadStreak = loadStreak ?? (() => StreakService.instance.load()),
        _syncHomeScreenWidgets =
            syncHomeScreenWidgets ?? _defaultSyncHomeScreenWidgets,
        _primeDeviceFingerprint =
            primeDeviceFingerprint ?? (() => DeviceFingerprint.get()),
        _initAppActivity =
            initAppActivity ?? (() => AppActivityService.instance.init()),
        _initPurchaseMode =
            initPurchaseMode ?? (() => PurchaseModeService.instance.init()),
        _onError = onError ?? _debugPrintError;

  final Future<void> Function() _loadTheme;
  final Future<void> Function() _initializeDateFormattingData;
  final Future<void> Function() _loadLocale;
  final Future<void> Function() _initAnalytics;
  final Future<void> Function(String languageCode) _setAnalyticsLanguage;
  final bool Function() _isAnalyticsEnabled;
  final Future<void> Function() _initFirebaseMessaging;
  final Future<void> Function() _initOneSignalAndLogin;
  final Future<void> Function() _initRevenueCatAndLogin;
  final Future<void> Function() _loadLastReadBook;
  final Future<void> Function() _loadStreak;
  final Future<void> Function() _syncHomeScreenWidgets;
  final Future<void> Function() _primeDeviceFingerprint;
  final void Function() _initAppActivity;
  final void Function() _initPurchaseMode;
  final void Function(String context, Object error, StackTrace stackTrace)
      _onError;

  bool _afterFirstFrameStarted = false;

  /// The app's own singleton — what `main()` actually calls. Tests build
  /// their own `AppBootstrapService(...)` with injected fakes instead of
  /// touching this one, so it never needs a reset hook.
  static final instance = AppBootstrapService();

  /// Theme and locale are independent local reads — nothing about the
  /// user's dark-mode preference depends on their language setting or vice
  /// versa — so they run in parallel. Date-formatting data has to be
  /// loaded before [AppLocale.load] sets `Intl.defaultLocale`, though: that
  /// assignment is only meaningful once the locale it points at actually
  /// has date symbols available, so that pair stays sequential inside its
  /// own branch.
  Future<void> runBeforeFirstFrame() async {
    await Future.wait([
      _loadTheme(),
      _prepareLocale(),
    ]);
  }

  Future<void> _prepareLocale() async {
    await _initializeDateFormattingData();
    await _loadLocale();
  }

  /// Everything here starts only after `runApp()` has already handed the
  /// first frame to the engine — nothing awaited here can delay it, and
  /// every branch is isolated from the others: one failing (a Firebase
  /// outage, a widget-sync exception, a slow network read) never stops the
  /// rest from starting or completing. Safe to call more than once — the
  /// second call is a no-op — so a caller doesn't have to reason about
  /// whether this has already run.
  Future<void> runAfterFirstFrame() async {
    if (_afterFirstFrameStarted) return;
    _afterFirstFrameStarted = true;
    await Future.wait([
      _isolate('analytics+fcm', _bootstrapAnalyticsAndFcm),
      // OneSignal is a top-level branch of its own, not nested inside the
      // analytics one — it's a second, independent push provider that
      // rides on nothing Firebase/Analytics owns, so a Firebase outage (or
      // a fake in a test that makes `initAnalytics` throw) must not stop
      // it from getting a chance to run, matching the original code's true
      // independence between the two.
      _isolate('onesignal', _initOneSignalAndLogin),
      _isolate('revenuecat', _initRevenueCatAndLogin),
      _isolate('reader-home-widgets', _bootstrapReaderHomeWidgets),
      _isolate('device-fingerprint', _primeDeviceFingerprint),
      _isolate('app-activity', () async => _initAppActivity()),
      _isolate('purchase-mode', () async => _initPurchaseMode()),
    ]);
  }

  /// Firebase Messaging only ever started once `AnalyticsService.init` had
  /// already resolved successfully — both ride the same Firebase app, and
  /// FCM has nothing to attach to if that never came up. Restructured from
  /// the old "await init(), then check a now-synchronous isEnabled flag"
  /// shape into a chain, since `initAnalytics` isn't awaited ahead of
  /// `runApp()` anymore and the check has to happen after it actually
  /// finishes, not at some arbitrary earlier point where it would always
  /// read false.
  Future<void> _bootstrapAnalyticsAndFcm() async {
    await _initAnalytics();
    unawaited(_isolate(
        'analytics-language', () => _setAnalyticsLanguage(_currentLanguage)));
    if (_isAnalyticsEnabled()) {
      unawaited(_isolate('firebase-messaging', _initFirebaseMessaging));
    }
  }

  String get _currentLanguage => AppLocale.instance.current.name;

  /// [HomeScreenWidgetService.sync] needs both stores loaded — it reads
  /// the last-read book's title/author/progress and the streak's current
  /// counters in the same call, so neither loading first on its own is
  /// enough. The native widget's own first update can lag a beat behind
  /// Flutter's startup; that's expected and fine, unlike blocking it ever
  /// being.
  Future<void> _bootstrapReaderHomeWidgets() async {
    await Future.wait([
      _isolate('last-read-book', _loadLastReadBook),
      _isolate('streak', _loadStreak),
    ]);
    await _isolate('home-screen-widget-sync', _syncHomeScreenWidgets);
  }

  /// Runs [action], reporting (never rethrowing) any failure — the shared
  /// shape every branch above uses so one going wrong can't reach another
  /// as an uncaught exception, whether this particular call is awaited by
  /// its caller or itself left unawaited.
  Future<void> _isolate(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _onError(label, error, stackTrace);
    }
  }

  static Future<void> _defaultSyncHomeScreenWidgets() {
    final lastRead = LastReadBookStore.instance.book;
    return HomeScreenWidgetService.sync(
      bookId: lastRead?.bookId,
      title: lastRead?.title,
      author: lastRead?.author,
      page: lastRead?.page ?? 0,
      pageCount: lastRead?.pageCount,
      streak: StreakService.instance.currentStreak,
      bestStreak: StreakService.instance.bestStreak,
      todayPages: StreakService.instance.todayPages,
      goalMinutes: StreakService.instance.goalMinMinutes,
      weekRead: StreakService.instance.weekRead,
      coverUrl: lastRead?.image == null
          ? null
          : ApiConfig.resolveImageUrl(lastRead!.image!),
    );
  }

  /// Never prints the error's own string interpolation of request
  /// data/tokens — startup failures here are things like "no network" or
  /// a plugin's `MissingPluginException`, not API responses, but staying
  /// terse (label + type) keeps this safe by construction either way.
  static void _debugPrintError(
      String context, Object error, StackTrace stackTrace) {
    debugPrint('AppBootstrapService[$context] failed: $error');
  }
}
