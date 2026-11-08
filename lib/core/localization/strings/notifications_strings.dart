import '../strings_base.dart';

/// Strings for [NotificationScreen], including the mock notification feed
/// content shown on that screen.
class NotificationsStrings {
  NotificationsStrings._();

  static String get title => t(
      tk: 'Bildirişler',
      ru: 'Уведомления',
      tr: 'Bildirimler',
      en: 'Notifications');
  static String get empty => t(
      tk: 'Entäk bildiriş ýok',
      ru: 'Пока нет уведомлений',
      tr: 'Henüz bildirim yok',
      en: 'No notifications yet');

  static String get newBookTitle => t(
      tk: 'Täze kitap goşuldy',
      ru: 'Добавлена новая книга',
      tr: 'Yeni kitap eklendi',
      en: 'New book added');
  static String get newBookBody => t(
        tk: '"Asman ýyldyzlary" kitaby indi elýeterli.',
        ru: 'Книга «Asman ýyldyzlary» теперь доступна.',
        tr: '"Asman ýyldyzlary" kitabı artık erişilebilir.',
        en: '"Asman ýyldyzlary" is now available.',
      );
  static String get newBookTime => t(
      tk: '2 sag ozal',
      ru: '2 часа назад',
      tr: '2 saat önce',
      en: '2 hours ago');

  static String get streakTitle => t(
      tk: 'Streak-iňizi ýitirmäň!',
      ru: 'Не потеряйте свою серию!',
      tr: 'Serinizi kaybetmeyin!',
      en: 'Don\'t lose your streak!');
  static String get streakBody => t(
        tk: 'Şu gün entäk okamadyňyz — 7 günlük yzly-yzyna okaýşyňyzy dowam etdiriň.',
        ru: 'Вы ещё не читали сегодня — продолжите свою 7-дневную серию чтения.',
        tr: 'Bugün henüz okumadınız — 7 günlük okuma serinizi sürdürün.',
        en: 'You haven\'t read today yet — keep your 7-day reading streak going.',
      );
  static String get streakTime => t(
      tk: '5 sag ozal',
      ru: '5 часов назад',
      tr: '5 saat önce',
      en: '5 hours ago');

  static String get discountTitle => t(
      tk: 'Abuna arzanladyşy',
      ru: 'Скидка на подписку',
      tr: 'Abonelik indirimi',
      en: 'Subscription discount');
  static String get discountBody => t(
        tk: 'Ýyllyk abuna üçin 20% arzanladyş — diňe şu hepde.',
        ru: 'Скидка 20% на годовую подписку — только на этой неделе.',
        tr: 'Yıllık abonelikte %20 indirim — sadece bu hafta.',
        en: '20% off the yearly subscription — this week only.',
      );
  static String get discountTime =>
      t(tk: 'Düýn', ru: 'Вчера', tr: 'Dün', en: 'Yesterday');

  static String get paymentTitle => t(
      tk: 'Töleg tassyklandy',
      ru: 'Платёж подтверждён',
      tr: 'Ödeme onaylandı',
      en: 'Payment confirmed');
  static String get paymentBody => t(
      tk: 'Balansyňyza 45 TMT goşuldy.',
      ru: 'На ваш баланс добавлено 45 TMT.',
      tr: 'Bakiyenize 45 TMT eklendi.',
      en: '45 TMT was added to your balance.');
  static String get paymentTime => t(
      tk: '3 gün ozal', ru: '3 дня назад', tr: '3 gün önce', en: '3 days ago');
}
