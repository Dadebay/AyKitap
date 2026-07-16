import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
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
    await _printTokens();
    await _requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _onMessageOpenedApp(initialMessage);

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _debugPrintColored('FCM token refreshed: $token', _AnsiColor.cyan);
    });
  }

  Future<void> _printTokens() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      _debugPrintColored('FCM token: $fcmToken', _AnsiColor.cyan);
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
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
