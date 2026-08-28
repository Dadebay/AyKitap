# OneSignal orange diagnostics

## Completed

- Added debug-only orange `🟠 [OneSignal]` console output.
- Added lifecycle logs for SDK initialization, permission, opt-in/out, login,
  logout, tag synchronization and notification opens.
- Added permission, push-subscription and OneSignal-user observers.
- Added state snapshots containing permission, opted-in state, subscription ID,
  FCM token presence, OneSignal ID and external ID.
- Masked device and subscription identifiers in console output.

## Verification

- `flutter analyze lib/core/services/onesignal_client.dart lib/core/services/onesignal_service.dart`
- Result: no issues found.
- No APK or application build was run, per user request.
