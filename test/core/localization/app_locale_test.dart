// Regression coverage for the S1 English-locale infra (see
// .Codex/SONNET_TRANSLATION_THEME_TASKS.md): `en` selects, persists, and the
// [t] helper falls back to `tk` when a string has no English translation yet.
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings_base.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLocale English support', () {
    test('setLanguage(en) updates current and persists across load()',
        () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.en);
      expect(AppLocale.instance.current, AppLanguageCode.en);
      expect(AppLocale.instance.locale.languageCode, 'en');

      // A fresh load() (simulating app restart) must still resolve to `en`
      // rather than silently reverting to the tk default.
      await AppLocale.instance.load();
      expect(AppLocale.instance.current, AppLanguageCode.en);

      // Leave global state as the other localization tests expect it.
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
    });

    test('t() returns the en translation when one is given', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.en);
      expect(t(tk: 'Salam', en: 'Hello'), 'Hello');
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
    });

    test('t() falls back to tk when no en translation exists yet', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.en);
      expect(t(tk: 'Salam', ru: 'Привет'), 'Salam');
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
    });
  });
}
