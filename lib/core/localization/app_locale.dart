import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The 3 UI languages offered on the Settings screen.
enum AppLanguageCode { tk, ru, tr }

/// App-wide language switch — same singleton pattern as [AppTheme]. Every
/// screen's strings read [AppLocale.instance.current] (via the [t] helper in
/// `strings_base.dart`) instead of hardcoding text, and the root widget
/// listens to this so switching language rebuilds the whole tree.
class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  static const _kLanguage = 'app_language_code';

  AppLanguageCode _current = AppLanguageCode.tk;
  AppLanguageCode get current => _current;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLanguage);
    _current = AppLanguageCode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppLanguageCode.tk,
    );
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguageCode value) async {
    if (_current == value) return;
    _current = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value.name);
  }
}
