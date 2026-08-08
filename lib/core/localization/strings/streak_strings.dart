import '../../models/streak.dart';
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

  /// Built from `GET /streaks/me`'s `goal_min_minutes` + `reward_rules`
  /// rather than hard-coded — the admin can change either, and the old
  /// static "15 min / 30 days / 10 manat" copy would silently go stale the
  /// moment they did.
  static String streakInfo(int goalMinMinutes, List<StreakRewardRule> rewardRules) {
    final goalPart = t(
      tk: 'Streak-i dowam etdirmek üçin her gün azyndan $goalMinMinutes minut okaň.',
      ru: 'Чтобы продолжить серию, читайте минимум $goalMinMinutes минут каждый день.',
      tr: 'Seriyi sürdürmek için her gün en az $goalMinMinutes dakika okuyun.',
    );
    final rewardParts = rewardRules.map((r) => ' ${_rewardRuleSentence(r)}').join();
    return '$goalPart$rewardParts';
  }

  static String _rewardRuleSentence(StreakRewardRule rule) {
    switch (rule.rewardType) {
      case StreakRewardType.balance:
        final amount = rule.amount ?? 0;
        return t(
          tk: '${rule.dayCount} gün yzly-yzyna okasaňyz, balansyňyza $amount TMT goşulýar.',
          ru: 'Если вы читаете ${rule.dayCount} дней подряд, на ваш баланс добавляется $amount TMT.',
          tr: '${rule.dayCount} gün üst üste okursanız, bakiyenize $amount TMT eklenir.',
        );
      case StreakRewardType.subscription:
        final months = rule.monthCount ?? 1;
        return t(
          tk: '${rule.dayCount} gün yzly-yzyna okasaňyz, $months aýlyk mugt abuna gazanýarsyňyz.',
          ru: 'Если вы читаете ${rule.dayCount} дней подряд, вы получаете $months мес. бесплатной подписки.',
          tr: '${rule.dayCount} gün üst üste okursanız, $months aylık ücretsiz abonelik kazanırsınız.',
        );
    }
  }

  // Reward congratulation dialog — shown when a report response comes back
  // with a non-empty `rewards[]`.
  static String get rewardTitle => t(tk: 'Gutlaýarys!', ru: 'Поздравляем!', tr: 'Tebrikler!');
  static String rewardBalanceMessage(int amount, int streakDay) => t(
        tk: '$streakDay gün yzly-yzyna okap, balansyňyza $amount TMT gazandyňyz!',
        ru: 'Вы читали $streakDay дней подряд и получили $amount TMT на баланс!',
        tr: '$streakDay gün üst üste okuyarak bakiyenize $amount TMT kazandınız!',
      );
  static String rewardSubscriptionMessage(int months, int streakDay) => t(
        tk: '$streakDay gün yzly-yzyna okap, $months aýlyk mugt abuna gazandyňyz!',
        ru: 'Вы читали $streakDay дней подряд и получили $months мес. бесплатной подписки!',
        tr: '$streakDay gün üst üste okuyarak $months aylık ücretsiz abonelik kazandınız!',
      );
  static String get rewardCta => t(tk: 'Ajaýyp!', ru: 'Отлично!', tr: 'Harika!');

  static String get readingHistory => t(tk: 'Okaýyş taryhy', ru: 'История чтения', tr: 'Okuma geçmişi');
  static String get noReadDaysYet => t(tk: 'Entäk okalan gün ýok', ru: 'Пока нет дней чтения', tr: 'Henüz okunan gün yok');
  static String get loadMore => t(tk: 'Ýene görkez', ru: 'Показать ещё', tr: 'Daha fazla');

  static String pagesLabel(int count) => t(tk: '$count sahypa', ru: '$count страниц', tr: '$count sayfa');
  static String minutesLabel(int count) => t(tk: '$count min', ru: '$count мин', tr: '$count dk');

  static String get monthlyReading => t(tk: 'Aýlyk okaýyş', ru: 'Чтение по месяцам', tr: 'Aylık okuma');
  static String get thisMonth => t(tk: 'Bu aý', ru: 'В этом месяце', tr: 'Bu ay');
  static String get lastMonth => t(tk: 'Geçen aý', ru: 'В прошлом месяце', tr: 'Geçen ay');
  static String get pagesRead => t(tk: 'Okalan sahypa', ru: 'Прочитано страниц', tr: 'Okunan sayfa');
  static String get readingTime => t(tk: 'Okalan wagt', ru: 'Время чтения', tr: 'Okuma süresi');
}
