# iOS foreground push notification

- Enabled iOS foreground presentation for Firebase Cloud Messaging alerts, badges, and sounds.
- Requests permission before retrieving the FCM token, ensuring the APNs registration has begun first.
- Adds a clear log line for the current notification authorization status.
- Avoids a duplicate local notification on iOS because Firebase now presents the remote notification itself.
- Verified with `flutter analyze lib/core/services/firebase_messaging_service.dart lib/core/services/local_notifications_service.dart`.
