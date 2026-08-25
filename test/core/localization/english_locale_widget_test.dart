// Widget-level regression for S2 (see .Codex/SONNET_TRANSLATION_THEME_TASKS.md):
// with AppLocale set to English, a screen's strings render in English rather
// than silently falling back to Türkmen.
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SettingsStrings render in English under the en locale',
      (tester) async {
    await AppLocale.instance.setLanguage(AppLanguageCode.en);
    addTearDown(() => AppLocale.instance.setLanguage(AppLanguageCode.tk));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text(SettingsStrings.title),
            Text(SettingsStrings.theme),
            Text(SettingsStrings.logout),
          ],
        ),
      ),
    ));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    // None of the Türkmen source strings should leak through.
    expect(find.text('Sazlamalar'), findsNothing);
    expect(find.text('Tema'), findsNothing);
    expect(find.text('Çykmak'), findsNothing);
  });
}
