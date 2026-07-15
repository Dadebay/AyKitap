import '../strings_base.dart';

/// Strings for [BookPurchaseScreen] and [SubscriptionScreen] (payment module).
class PaymentStrings {
  PaymentStrings._();

  // book_purchase_screen.dart
  static String get purchaseTitle => t(tk: 'Satyn alyş', ru: 'Покупка', tr: 'Satın alma');
  static String purchasedSnackbar(String title) => t(
        tk: '«$title» satyn alyndy',
        ru: '«$title» приобретена',
        tr: '«$title» satın alındı',
      );
  static String get balanceNotEnough => t(tk: 'Balans ýeterlik däl', ru: 'Недостаточно средств на балансе', tr: 'Bakiye yetersiz');
  static String get bookPrice => t(tk: 'Kitabyň bahasy', ru: 'Цена книги', tr: 'Kitabın fiyatı');
  static String get yourBalance => t(tk: 'Balansyňyz', ru: 'Ваш баланс', tr: 'Bakiyeniz');
  static String get afterPurchase => t(tk: 'Satyn alandan soň', ru: 'После покупки', tr: 'Satın aldıktan sonra');
  static String get notEnough => t(tk: 'Ýeterlik däl', ru: 'Недостаточно', tr: 'Yetersiz');
  static String manat(num amount) => t(tk: '$amount manat', ru: '$amount манат', tr: '$amount manat');
  static String get balanceInsufficientNote => t(
        tk: 'Balansyňyz bu kitaby almaga ýetmeýär. Balansy dolduryň.',
        ru: 'Вашего баланса недостаточно для покупки этой книги. Пополните баланс.',
        tr: 'Bakiyeniz bu kitabı almaya yetmiyor. Bakiyenizi yükleyin.',
      );
  static String get booksOnlyInApp => t(
        tk: 'Kitaplar diňe programmada okalýar — telefona ýüklenmeýär.',
        ru: 'Книги читаются только в приложении — на телефон не скачиваются.',
        tr: 'Kitaplar yalnızca uygulama içinde okunur — telefona indirilmez.',
      );
  static String confirmWithPrice(num amount) => t(
        tk: 'Tassykla — $amount manat',
        ru: 'Подтвердить — $amount манат',
        tr: 'Onayla — $amount manat',
      );
  static String get topUpBalance => t(tk: 'Balans doldur', ru: 'Пополнить баланс', tr: 'Bakiye yükle');

  // subscription_screen.dart
  static String get planWeekly => t(tk: 'Hepdelik', ru: 'Недельный', tr: 'Haftalık');
  static String get planMonthly => t(tk: 'Aýlyk', ru: 'Месячный', tr: 'Aylık');
  static String get plan3Months => t(tk: '3 Aýlyk', ru: '3 месяца', tr: '3 Aylık');
  static String get plan6Months => t(tk: '6 Aýlyk', ru: '6 месяцев', tr: '6 Aylık');
  static String get subscriptionTitle => t(tk: 'Abunalyk', ru: 'Подписка', tr: 'Abonelik');
  static String get unlimitedAccessTitle => t(
        tk: 'Ähli kitaplara çäksiz giriş',
        ru: 'Неограниченный доступ ко всем книгам',
        tr: 'Tüm kitaplara sınırsız erişim',
      );
  static String get unlimitedAccessSubtitle => t(
        tk: 'Abunalyk dowam edýänçä ähli kitaplary okap bilersiňiz.',
        ru: 'Пока подписка активна, вы можете читать все книги.',
        tr: 'Abonelik devam ettiği sürece tüm kitapları okuyabilirsiniz.',
      );
  static String planSelectedMock(String planName) => t(
        tk: '$planName plan saýlandy (mock)',
        ru: 'Выбран план $planName (демо)',
        tr: '$planName planı seçildi (mock)',
      );
  static String subscribeWithPrice(num amount) => t(
        tk: '$amount manat — Abuna bol',
        ru: '$amount манат — Оформить подписку',
        tr: '$amount manat — Abone ol',
      );
  static String get mostPopular => t(tk: 'Iň meşhur', ru: 'Самый популярный', tr: 'En popüler');
  static String subscriptionActivated(String planName) => t(
        tk: '$planName abunalyk işjeňleşdirildi',
        ru: 'Подписка «$planName» активирована',
        tr: '$planName aboneliği etkinleştirildi',
      );
  static String get activeSubscription => t(tk: 'Işjeň abunalyk', ru: 'Активная подписка', tr: 'Aktif abonelik');
  static String activeUntil(String date) => t(tk: '$date çenli güýjünde', ru: 'Действует до $date', tr: '$date tarihine kadar geçerli');
  static String get renew => t(tk: 'Uzalt', ru: 'Продлить', tr: 'Yenile');
}
