import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/localization_delegates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps a bare MaterialApp wired exactly like the real one, then reads the
/// localizations the framework resolved for [locale].
Future<MaterialLocalizations> _resolveMaterialLocalizations(
  WidgetTester tester,
  Locale locale,
) async {
  late MaterialLocalizations resolved;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: kAppSupportedLocales,
      localizationsDelegates: kAppLocalizationsDelegates,
      home: Builder(
        builder: (context) {
          resolved = MaterialLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('every offered language resolves MaterialLocalizations', (tester) async {
    for (final locale in kAppSupportedLocales) {
      final l10n = await _resolveMaterialLocalizations(tester, locale);
      expect(l10n.okButtonLabel, isNotEmpty, reason: 'failed for $locale');
    }
  });

  testWidgets('Türkmen borrows Turkish for built-in widgets', (tester) async {
    final tk = await _resolveMaterialLocalizations(tester, const Locale('tk'));
    final tr = await _resolveMaterialLocalizations(tester, const Locale('tr'));
    final ru = await _resolveMaterialLocalizations(tester, const Locale('ru'));

    expect(tk.cancelButtonLabel, tr.cancelButtonLabel);
    expect(tk.cancelButtonLabel, isNot(ru.cancelButtonLabel));
  });

  test('Intl.defaultLocale follows the language switch', () async {
    final date = DateTime(2026, 7, 15);

    await AppLocale.instance.setLanguage(AppLanguageCode.ru);
    expect(DateFormat.yMMMd().format(date), contains('июл'));

    await AppLocale.instance.setLanguage(AppLanguageCode.tr);
    expect(DateFormat.yMMMd().format(date), contains('Tem'));

    // Türkmen has no intl data, so it must fall back to Turkish rather than
    // silently reverting to en_US.
    await AppLocale.instance.setLanguage(AppLanguageCode.tk);
    expect(DateFormat.yMMMd().format(date), contains('Tem'));
  });
}
