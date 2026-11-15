import '../services/currency.dart';
import 'app_locale.dart';

/// A string with its Türkmen / Russian / Turkish translations. Every
/// `StringsXxx` class (one per module, e.g. `HomeStrings`) is a set of
/// `static String get someLabel => t(tk: '...', ru: '...', tr: '...');`
/// getters built on top of this.
///
/// [tk] is required — it's always the source-of-truth baseline the app
/// shipped with — [ru], [tr] and [en] are optional while translations are
/// filled in incrementally; each falls back to [tk] when missing.
String t({required String tk, String? ru, String? tr, String? en}) {
  final String text;
  switch (AppLocale.instance.current) {
    case AppLanguageCode.tk:
      text = tk;
    case AppLanguageCode.ru:
      text = ru ?? tk;
    case AppLanguageCode.tr:
      text = tr ?? tk;
    case AppLanguageCode.en:
      text = en ?? tk;
  }
  // "TMT" -> "$" for accounts that signed in with Google/Apple/email.
  return Currency.localize(text);
}
