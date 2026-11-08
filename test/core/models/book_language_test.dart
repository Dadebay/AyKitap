// The filter page's "Dil" chips read [BookLanguage.label], which picks one of
// the names `GET /book-languages` returns. The endpoint carries no `en` name,
// and English used to resolve to '' and fall through to Türkmen — so an
// English-language filter page listed "Türkmençe, Iňlizce, Rusça".
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/models/book_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _russian = BookLanguage(
  id: 3,
  nameTk: 'Rusça',
  nameRu: 'Русский',
  // What the backend actually fills this slot with today: the
  // internationally-recognisable spelling rather than a Turkish one.
  nameTr: 'Russian',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => AppLocale.instance.setLanguage(AppLanguageCode.tk));

  Future<String> labelIn(AppLanguageCode code, BookLanguage language) async {
    await AppLocale.instance.setLanguage(code);
    return language.label;
  }

  test('each UI language reads its own name', () async {
    expect(await labelIn(AppLanguageCode.tk, _russian), 'Rusça');
    expect(await labelIn(AppLanguageCode.ru, _russian), 'Русский');
    expect(await labelIn(AppLanguageCode.tr, _russian), 'Russian');
  });

  test('English borrows the Turkish slot rather than falling back to Türkmen',
      () async {
    expect(await labelIn(AppLanguageCode.en, _russian), 'Russian');
    expect(await labelIn(AppLanguageCode.en, _russian), isNot('Rusça'));
  });

  test('a chip never renders blank when a translation is missing', () async {
    const onlyTurkmen =
        BookLanguage(id: 9, nameTk: 'Hytaý', nameRu: '', nameTr: '');

    for (final code in AppLanguageCode.values) {
      expect(await labelIn(code, onlyTurkmen), 'Hytaý',
          reason: '$code should still show something');
    }
  });

  test('fromJson reads the nested name object, tolerating missing keys', () {
    final parsed = BookLanguage.fromJson({
      'id': 1,
      'name': {'tk': 'Türkmençe', 'tr': 'Turkmen'},
    });

    expect(parsed.id, 1);
    expect(parsed.nameTk, 'Türkmençe');
    expect(parsed.nameTr, 'Turkmen');
    expect(parsed.nameRu, isEmpty);
  });

  test('a row with no name object at all does not throw', () {
    final parsed = BookLanguage.fromJson({'id': 7});

    expect(parsed.id, 7);
    expect(parsed.label, isEmpty);
  });
}
