import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:aykitap/core/localization/strings/profile_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses Doldur for Turkmen top-up actions', () async {
    SharedPreferences.setMockInitialValues({});
    await AppLocale.instance.setLanguage(AppLanguageCode.tk);

    expect(ProfileStrings.topUpBalance, 'Doldur');
    expect(PaymentStrings.topUpBalance, 'Balans doldur');
  });
}
