import '../strings_base.dart';

/// Strings for [NotificationScreen], including the mock notification feed
/// content shown on that screen.
class NotificationsStrings {
  NotificationsStrings._();

  static String get title => t(tk: 'Bildirişler', ru: 'Уведомления', tr: 'Bildirimler');
  static String get empty => t(tk: 'Entäk bildiriş ýok', ru: 'Пока нет уведомлений', tr: 'Henüz bildirim yok');

  static String get newBookTitle => t(tk: 'Täze kitap goşuldy', ru: 'Добавлена новая книга', tr: 'Yeni kitap eklendi');
  static String get newBookBody => t(
        tk: '"Asman ýyldyzlary" kitaby indi elýeterli.',
        ru: 'Книга «Asman ýyldyzlary» теперь доступна.',
        tr: '"Asman ýyldyzlary" kitabı artık erişilebilir.',
      );
  static String get newBookTime => t(tk: '2 sag ozal', ru: '2 часа назад', tr: '2 saat önce');

  static String get streakTitle => t(tk: 'Streak-iňizi ýitirmäň!', ru: 'Не потеряйте свою серию!', tr: 'Serinizi kaybetmeyin!');
  static String get streakBody => t(
        tk: 'Şu gün entäk okamadyňyz — 7 günlük yzly-yzyna okaýşyňyzy dowam etdiriň.',
        ru: 'Вы ещё не читали сегодня — продолжите свою 7-дневную серию чтения.',
        tr: 'Bugün henüz okumadınız — 7 günlük okuma serinizi sürdürün.',
      );
  static String get streakTime => t(tk: '5 sag ozal', ru: '5 часов назад', tr: '5 saat önce');

  static String get discountTitle => t(tk: 'Abuna arzanladyşy', ru: 'Скидка на подписку', tr: 'Abonelik indirimi');
  static String get discountBody => t(
        tk: 'Ýyllyk abuna üçin 20% arzanladyş — diňe şu hepde.',
        ru: 'Скидка 20% на годовую подписку — только на этой неделе.',
        tr: 'Yıllık abonelikte %20 indirim — sadece bu hafta.',
      );
  static String get discountTime => t(tk: 'Düýn', ru: 'Вчера', tr: 'Dün');

  static String get paymentTitle => t(tk: 'Töleg tassyklandy', ru: 'Платёж подтверждён', tr: 'Ödeme onaylandı');
  static String get paymentBody => t(tk: 'Balansyňyza 45 TMT goşuldy.', ru: 'На ваш баланс добавлено 45 TMT.', tr: 'Bakiyenize 45 TMT eklendi.');
  static String get paymentTime => t(tk: '3 gün ozal', ru: '3 дня назад', tr: '3 gün önce');
}
