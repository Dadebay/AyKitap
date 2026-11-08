import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppLocale.instance.setLanguage(AppLanguageCode.tk));

  DioException connectionFailure() => DioException(
        requestOptions: RequestOptions(path: '/books/all'),
        type: DioExceptionType.connectionError,
      );

  test('connection failure follows the selected English locale', () async {
    await AppLocale.instance.setLanguage(AppLanguageCode.en);

    final error = ApiException.fromDioException(connectionFailure());

    expect(error.message, 'Could not connect to the internet.');
  });

  test('connection failure uses the corrected Turkmen wording', () async {
    await AppLocale.instance.setLanguage(AppLanguageCode.tk);

    final error = ApiException.fromDioException(connectionFailure());

    expect(error.message, 'Internete birigip bolmady.');
  });
}
