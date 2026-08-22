import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'auth_api_service.dart';
import 'auth_session.dart';
import 'local_notifications_service.dart';

/// Push notifications — same singleton pattern as [AnalyticsService].
/// Firebase itself is already brought up by `AnalyticsService.init()` before
/// this runs, so [init] doesn't call [Firebase.initializeApp] again; the
/// background handler runs in its own isolate though, which doesn't share
/// that state, so it guards its own init.
class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  Future<void> init() async {
    await LocalNotificationsService.instance.init();
    await _requestPermission();
    // Firebase deliberately suppresses notification banners while an iOS app
    // is open unless these presentation options are set. This is independent
    // of the user's notification permission.
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // On iOS, APNs registration is initiated by the permission request. Get
    // the FCM token only afterwards, so it is correctly associated with the
    // APNs token before it is used by Firebase Console or our backend.
    await _printTokens();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _onMessageOpenedApp(initialMessage);

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _debugPrintColored('FCM token refreshed: $token', _AnsiColor.cyan);
      unawaited(_syncTokenWithBackend(token));
    });
  }

  /// Re-sends whatever FCM token this device currently holds. Boot-time
  /// [_printTokens] fires before a fresh login exists in [AuthSession], so
  /// its own sync attempt is a no-op then — callers like [OtpVerifyScreen]
  /// call this right after a successful login to close that gap without
  /// waiting for the next [onTokenRefresh] event (which can be days later).
  Future<void> syncCurrentTokenIfLoggedIn() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _syncTokenWithBackend(token);
    } catch (e) {
      _debugPrintColored('FCM token fetch failed: $e', _AnsiColor.red);
    }
  }

  /// Never throws — a push-token sync failure must not surface anywhere
  /// near login or app boot, both of which call this in fire-and-forget style.
  ///
  /// [init]'s `onTokenRefresh` listener, [syncCurrentTokenIfLoggedIn], and
  /// boot-time [_printTokens] all funnel through here and mostly report the
  /// same still-current token — PATCHing every time would be a request per
  /// app launch for nothing, so this skips the call when [token] matches
  /// the last one that actually made it to the backend.
  Future<void> _syncTokenWithBackend(String token) async {
    if (!await AuthSession.isLoggedIn()) return;
    if (await AuthSession.getLastSyncedFcmToken() == token) return;
    try {
      await AuthApiService.updateFcmToken(fcmToken: token);
      await AuthSession.saveLastSyncedFcmToken(token);
    } catch (e) {
      _debugPrintColored('FCM token sync failed: $e', _AnsiColor.red);
    }
  }

  Future<void> _printTokens() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      _debugPrintColored('FCM token: $fcmToken', _AnsiColor.cyan);
      if (fcmToken != null) unawaited(_syncTokenWithBackend(fcmToken));
    } catch (e) {
      _debugPrintColored('FCM token fetch failed: $e', _AnsiColor.red);
    }

    try {
      // iOS only — null on Android, and on iOS until the APNs handshake
      // completes (can take a beat right after a fresh install).
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      _debugPrintColored('APNS token: $apnsToken', _AnsiColor.magenta);
    } catch (e) {
      _debugPrintColored('APNS token fetch failed: $e', _AnsiColor.red);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    _debugPrintColored(
      'Push permission: ${settings.authorizationStatus.name}',
      settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional
          ? _AnsiColor.cyan
          : _AnsiColor.red,
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    // iOS now presents the remote message itself (configured in [init]). A
    // second local notification here would create duplicate banners.
    if (notification != null && !Platform.isIOS) {
      LocalNotificationsService.instance.showNotification(
        notification.title,
        notification.body,
        message.data.toString(),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// ANSI colour codes — most terminals `flutter run` prints into (including
/// VS Code's and Android Studio's) render these, so the token lines jump
/// out instead of blending into the wall of platform log noise around them.
enum _AnsiColor {
  cyan('\x1B[36m'),
  magenta('\x1B[35m'),
  red('\x1B[31m');

  final String code;
  const _AnsiColor(this.code);
}

const _ansiReset = '\x1B[0m';

void _debugPrintColored(String message, _AnsiColor color) {
  debugPrint('${color.code}$message$_ansiReset');
}
