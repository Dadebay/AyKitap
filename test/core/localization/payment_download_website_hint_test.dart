import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('purchase download website hint is translated in every app language',
      () async {
    const expected = {
      AppLanguageCode.tk:
          'Faýly ýükläp almak üçin www.aykitap.com.tm saýtyny ulanyň.',
      AppLanguageCode.ru:
          'Чтобы скачать файл, используйте сайт www.aykitap.com.tm.',
      AppLanguageCode.tr:
          'Dosyayı indirmek için www.aykitap.com.tm adresini kullanın.',
      AppLanguageCode.en: 'To download the file, use www.aykitap.com.tm.',
    };

    for (final entry in expected.entries) {
      await AppLocale.instance.setLanguage(entry.key);
      expect(PaymentStrings.downloadFileWebsiteText, entry.value);
    }

    await AppLocale.instance.setLanguage(AppLanguageCode.tk);
  });
}
