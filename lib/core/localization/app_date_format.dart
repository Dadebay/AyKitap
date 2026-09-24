import 'package:intl/intl.dart';

import 'app_locale.dart';

/// Date formatting that follows the *app's* language rather than `intl`'s.
///
/// `intl` ships no Türkmen locale data, so [AppLocale] points
/// `Intl.defaultLocale` at Turkish for `tk` (see [kTurkmenFallbackLocale]).
/// That borrowing is right for digits, separators and clock format, but wrong
/// for month names: a Türkmen reader was shown the Turkish "Eyl" where
/// Türkmenistan writes "Sent(ýabr)". The month names are therefore spelled
/// out here for `tk`, and left to `intl` for the three locales it actually
/// has data for.
///
/// Every date the user reads should go through this rather than a bare
/// `DateFormat.yMMMd()`, which silently picks up the fallback locale again.
abstract final class AppDateFormat {
  /// Abbreviated, to sit on one line the way the Turkish forms these replace
  /// did ("Eyl" → "Sent"). Mart, Maý, Iýun and Iýul are left whole: they are
  /// already short, and clipping the last two to three letters would make
  /// June and July the same word.
  static const _turkmenMonths = <String>[
    'Ýan',
    'Few',
    'Mart',
    'Apr',
    'Maý',
    'Iýun',
    'Iýul',
    'Awg',
    'Sent',
    'Okt',
    'Noý',
    'Dek',
  ];

  static bool get _isTurkmen =>
      AppLocale.instance.current == AppLanguageCode.tk;

  /// A calendar day — "24 Sent 2026" in Türkmen, the locale's own short form
  /// ("Sep 24, 2026", "24 Eyl 2026") everywhere else.
  static String date(DateTime value) => _isTurkmen
      ? '${value.day} ${_turkmenMonths[value.month - 1]} ${value.year}'
      : DateFormat.yMMMd().format(value);

  /// A day and a wall-clock time — "24 Sent 2026 10:56".
  ///
  /// The time half is left to `intl` even in Türkmen: the fallback locale
  /// renders it as 24-hour `HH:mm`, which is what Türkmenistan uses, and
  /// hand-rolling it would only risk losing that.
  static String dateTime(DateTime value) => _isTurkmen
      ? '${date(value)} ${DateFormat.Hm().format(value)}'
      : DateFormat.yMMMd().add_Hm().format(value);
}
