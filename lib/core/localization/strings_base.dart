import 'app_locale.dart';

/// A string with its Türkmen / Russian / Turkish translations. Every
/// `StringsXxx` class (one per module, e.g. `HomeStrings`) is a set of
/// `static String get someLabel => t(tk: '...', ru: '...', tr: '...');`
/// getters built on top of this.
///
/// [tk] is required — it's always the source-of-truth baseline the app
/// shipped with — [ru] and [tr] are optional while translations are filled
/// in incrementally; either falls back to [tk] when missing.
String t({required String tk, String? ru, String? tr}) {
  switch (AppLocale.instance.current) {
    case AppLanguageCode.tk:
      return tk;
    case AppLanguageCode.ru:
      return ru ?? tk;
    case AppLanguageCode.tr:
      return tr ?? tk;
  }
}
