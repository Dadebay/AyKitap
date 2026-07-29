import '../strings_base.dart';

/// Strings for [StreakScreen].
class StreakStrings {
  StreakStrings._();

  static String get title => t(tk: 'Streak', ru: 'Серия', tr: 'Seri');

  static const _monthsTk = ['Ýanwar', 'Fewral', 'Mart', 'Aprel', 'Maý', 'Iýun', 'Iýul', 'Awgust', 'Sentýabr', 'Oktýabr', 'Noýabr', 'Dekabr'];
  static const _monthsRu = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  static const _monthsTr = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

  /// [monthIndex1based] is 1 for January .. 12 for December, matching
  /// `DateTime.month`.
  static String month(int monthIndex1based) => t(
        tk: _monthsTk[monthIndex1based - 1],
        ru: _monthsRu[monthIndex1based - 1],
        tr: _monthsTr[monthIndex1based - 1],
      );

  static String get today => t(tk: 'Şu gün', ru: 'Сегодня', tr: 'Bugün');
  static String get yesterday => t(tk: 'Düýn', ru: 'Вчера', tr: 'Dün');

  static String currentStreakLabel(int days) => t(tk: '$days gün yzly-yzyna', ru: '$days дней подряд', tr: '$days gün üst üste');
  static String bestStreakLabel(int days) => t(tk: 'Iň gowy netije: $days gün', ru: 'Лучший результат: $days дней', tr: 'En iyi sonuç: $days gün');

  static String get thisWeek => t(tk: 'Bu hepde', ru: 'На этой неделе', tr: 'Bu hafta');

  static String get streakInfo => t(
        tk: 'Streak-i dowam etdirmek üçin her gün azyndan 15 minut okaň. 30 gün yzly-yzyna okasaňyz, balansyňyza 10 manat goşulýar.',
        ru: 'Чтобы продолжить серию, читайте минимум 15 минут каждый день. Если вы читаете 30 дней подряд, на ваш баланс добавляется 10 манат.',
        tr: 'Seriyi sürdürmek için her gün en az 15 dakika okuyun. 30 gün üst üste okursanız, bakiyenize 10 manat eklenir.',
      );

  static String get readingHistory => t(tk: 'Okaýyş taryhy', ru: 'История чтения', tr: 'Okuma geçmişi');
  static String get noReadDaysYet => t(tk: 'Entäk okalan gün ýok', ru: 'Пока нет дней чтения', tr: 'Henüz okunan gün yok');

  static String pagesLabel(int count) => t(tk: '$count sahypa', ru: '$count страниц', tr: '$count sayfa');
  static String minutesLabel(int count) => t(tk: '$count min', ru: '$count мин', tr: '$count dk');

  static String get monthlyReading => t(tk: 'Aýlyk okaýyş', ru: 'Чтение по месяцам', tr: 'Aylık okuma');
  static String get thisMonth => t(tk: 'Bu aý', ru: 'В этом месяце', tr: 'Bu ay');
  static String get lastMonth => t(tk: 'Geçen aý', ru: 'В прошлом месяце', tr: 'Geçen ay');
  static String get pagesRead => t(tk: 'Okalan sahypa', ru: 'Прочитано страниц', tr: 'Okunan sayfa');
  static String get readingTime => t(tk: 'Okalan wagt', ru: 'Время чтения', tr: 'Okuma süresi');
}
