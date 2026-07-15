import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for app-level flags.
/// Keeps the "has the user finished onboarding?" state so the intro is
/// only ever shown once.
class AppPrefs {
  AppPrefs._();

  static const _kOnboardingSeen = 'onboarding_seen';

  static Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeen) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeen, true);
  }
}
