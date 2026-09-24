// Türkmen dates used to render with Turkish month names, because `intl` has
// no `tk` data and [AppLocale] points `Intl.defaultLocale` at Turkish as a
// fallback — so a balance row dated September read "24 Eyl 2026" to a Türkmen
// reader instead of "24 Sent 2026". [AppDateFormat] is what fixed that; these
// pin both halves of it, the Türkmen months and the untouched other locales.
import 'package:aykitap/core/localization/app_date_format.dart';
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeDateFormatting);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Every test leaves the singleton back on the app's default language, the
  // way the other localization tests in this directory do.
  tearDown(() => AppLocale.instance.setLanguage(AppLanguageCode.tk));

  group('AppDateFormat in Türkmen', () {
    test('uses Türkmen month names, not the Turkish fallback', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
      expect(AppDateFormat.date(DateTime(2026, 9, 24)), '24 Sent 2026');
    });

    test('keeps a 24-hour time alongside the date', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
      expect(AppDateFormat.dateTime(DateTime(2026, 9, 24, 10, 56)),
          '24 Sent 2026 10:56');
    });

    test('names every month, and June and July stay distinguishable',
        () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.tk);
      final months = [
        for (var m = 1; m <= 12; m++) AppDateFormat.date(DateTime(2026, m, 1))
      ];
      expect(months, [
        '1 Ýan 2026',
        '1 Few 2026',
        '1 Mart 2026',
        '1 Apr 2026',
        '1 Maý 2026',
        '1 Iýun 2026',
        '1 Iýul 2026',
        '1 Awg 2026',
        '1 Sent 2026',
        '1 Okt 2026',
        '1 Noý 2026',
        '1 Dek 2026',
      ]);
    });
  });

  group('AppDateFormat in the locales intl does have data for', () {
    test('English keeps the locale\'s own short form', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.en);
      expect(AppDateFormat.date(DateTime(2026, 9, 24)), 'Sep 24, 2026');
    });

    test('Russian keeps the locale\'s own short form', () async {
      await AppLocale.instance.setLanguage(AppLanguageCode.ru);
      // Not asserted verbatim: `intl` has changed Russian abbreviations
      // between versions (with and without the trailing period), and this
      // test is about *which* language is used, not about pinning CLDR.
      final formatted = AppDateFormat.date(DateTime(2026, 9, 24));
      expect(formatted, contains('2026'));
      expect(formatted, contains('24'));
      expect(formatted, isNot(contains('Sent')));
    });
  });
}
