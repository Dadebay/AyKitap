import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localization_delegates.dart';

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

  /// Handed to `MaterialApp.locale` so Flutter's own widgets follow the
  /// in-app language switch instead of the device's.
  Locale get locale => Locale(_current.name);

  /// What `intl` should format dates and numbers with. Türkmen has no `intl`
  /// data, so it borrows Turkish — see [kTurkmenFallbackLocale].
  String get _intlLocaleName => switch (_current) {
        AppLanguageCode.tk => kTurkmenFallbackLocale.languageCode,
        AppLanguageCode.ru => 'ru',
        AppLanguageCode.tr => 'tr',
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLanguage);
    _current = AppLanguageCode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AppLanguageCode.tk,
    );
    Intl.defaultLocale = _intlLocaleName;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguageCode value) async {
    if (_current == value) return;
    _current = value;
    // Bare `DateFormat.yMMMd()` calls read this, so it has to move in lockstep
    // with the language or dates keep rendering in the previous one.
    Intl.defaultLocale = _intlLocaleName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value.name);
  }
}
