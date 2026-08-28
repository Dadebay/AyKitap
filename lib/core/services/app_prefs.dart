import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for app-level flags.
/// Keeps the "has the user finished onboarding?" state so the intro is
/// only ever shown once.
class AppPrefs {
  AppPrefs._();

  static const _kOnboardingSeen = 'onboarding_seen';
  static const _kNotificationPromptSeen = 'notification_prompt_seen';
  static const _kNotificationsEnabled = 'notifications_enabled';

  static Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeen) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
  }

  /// Whether the in-app notification explanation has been shown once.
  ///
  /// Set whichever way the user answered — "Häzir däl" is an answer, and
  /// re-asking on every launch is exactly what makes a permission prompt
  /// feel like nagging. Settings keeps a way back in (see
  /// [NotificationPermissionFlow.requestFromSettings]).
  static Future<bool> isNotificationPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationPromptSeen) ?? false;
  }

  static Future<void> setNotificationPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationPromptSeen, true);
  }

  /// The Settings switch's own state, independent of OS permission.
  ///
  /// An app can't revoke its own notification permission — only the system
  /// settings page can — so an in-app switch has to be backed by something
  /// the app *does* control: the push subscription. This is that intent,
  /// persisted so it survives a restart and can be re-applied to the SDK on
  /// the next launch. Defaults to on: a user who was never asked hasn't
  /// opted out of anything.
  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
  }
}
