import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Displays push notifications as native local notifications while the app
/// is in the foreground — [FirebaseMessaging.onMessage] fires but, unlike
/// background/terminated pushes, doesn't show anything on its own.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  late final FlutterLocalNotificationsPlugin _plugin;
  final _androidChannel = const AndroidNotificationChannel(
    'channel_id',
    'Channel name',
    description: 'Push notification channel',
    importance: Importance.max,
  );

  bool _initialized = false;
  int _notificationIdCounter = 0;

  Future<void> init() async {
    if (_initialized) return;
    _plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_androidChannel);
    _initialized = true;
  }

  Future<void> showNotification(String? title, String? body, String? payload) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      _notificationIdCounter++,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}
