import '../app_locale.dart';

/// Strings shared by widgets under lib/core/widgets/ — not tied to any one
/// module screen, so they don't belong in a per-module Strings class.
class CommonStrings {
  CommonStrings._();

  /// Mon..Sun weekday abbreviations for [StreakWeekRow]'s 7-day strip.
  static List<String> get weekdayLetters {
    switch (AppLocale.instance.current) {
      case AppLanguageCode.tk:
        return const [
          'D',
          'S',
          'Ç',
          'P',
          'A',
          'Ş',
          'Ý'
        ]; // Du,Si,Çe,Pe,An,Şe,Ýe
      case AppLanguageCode.ru:
        return const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      case AppLanguageCode.tr:
        return const ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
      case AppLanguageCode.en:
        return const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    }
  }
}
