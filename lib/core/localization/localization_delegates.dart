import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Türkmen has no data in `flutter_localizations` (it ships 116 languages;
/// `tk` isn't one) nor in `intl` (120 date locales; `tk` isn't one either).
/// Turkish is the closest supported language, so Flutter's own widgets — the
/// text selection toolbar, date pickers, semantics labels — and `intl`'s date
/// formatting speak Turkish while the app's own [t] strings stay Türkmen.
const Locale kTurkmenFallbackLocale = Locale('tr');

/// The languages offered on the Settings screen, in [AppLanguageCode] order.
/// `tk` is first so it also acts as the resolution fallback for any unexpected
/// device locale. `en` needs no custom delegate below (unlike `tk`) — it's a
/// language `flutter_localizations`/`intl` already ship data for.
const List<Locale> kAppSupportedLocales = <Locale>[
  Locale('tk'),
  Locale('ru'),
  Locale('tr'),
  Locale('en'),
];

/// Without these, `MaterialApp` asserts "No MaterialLocalizations found" the
/// moment `tk` is selected, because the Global delegates below report `tk` as
/// unsupported. [Localizations] uses the *first* delegate of each type whose
/// `isSupported` returns true, so the `tk` interceptors must precede them.
const List<LocalizationsDelegate<dynamic>> kAppLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  _TurkmenMaterialLocalizationsDelegate(),
  _TurkmenCupertinoLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _TurkmenMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TurkmenMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tk';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(kTurkmenFallbackLocale);

  @override
  bool shouldReload(_TurkmenMaterialLocalizationsDelegate old) => false;
}

class _TurkmenCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TurkmenCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tk';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(kTurkmenFallbackLocale);

  @override
  bool shouldReload(_TurkmenCupertinoLocalizationsDelegate old) => false;
}
