import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/auth_strings.dart';
import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses the Premium product name in every supported language', () async {
    for (final language in AppLanguageCode.values) {
      await AppLocale.instance.setLanguage(language);

      expect(PaymentStrings.plusPlanName, 'Aýkitap Premium');
      expect(AuthStrings.welcomeBonusBody('10'), contains('Premium'));
      expect(AuthStrings.welcomeBonusBody('10'), isNot(contains('Plus')));
    }

    await AppLocale.instance.setLanguage(AppLanguageCode.tk);
  });
}
