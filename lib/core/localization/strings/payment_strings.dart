import '../strings_base.dart';

/// Strings for [BookPurchaseScreen] and [SubscriptionScreen] (payment module).
class PaymentStrings {
  PaymentStrings._();

  // payment_webview_screen.dart
  static String get paymentPageTitle => t(tk: 'Töleg', ru: 'Оплата', tr: 'Ödeme');

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
  /// Currency code is deliberately the same in every language and screen.
  static String manat(num amount) => '$amount TMT';
  static String get balanceInsufficientNote => t(
        tk: 'Balansyňyz bu kitaby almaga ýetmeýär. Balansy dolduryň.',
        ru: 'Вашего баланса недостаточно для покупки этой книги. Пополните баланс.',
        tr: 'Bakiyeniz bu kitabı almaya yetmiyor. Bakiyenizi yükleyin.',
      );
  /// Exact shortfall for [InsufficientBalanceDialog] — how much more the
  /// balance needs before this purchase goes through.
  static String balanceShortfall(num amount) => t(
        tk: 'Bu kitaby almak üçin ýene $amount TMT gerek. Balansy dolduryň.',
        ru: 'Для покупки этой книги не хватает $amount TMT. Пополните баланс.',
        tr: 'Bu kitabı almak için $amount TMT daha gerekli. Bakiyenizi yükleyin.',
      );
  static String get booksOnlyInApp => t(
        tk: 'Kitaplar diňe programmada okalýar — telefona ýüklenmeýär.',
        ru: 'Книги читаются только в приложении — на телефон не скачиваются.',
        tr: 'Kitaplar yalnızca uygulama içinde okunur — telefona indirilmez.',
      );
  static String confirmWithPrice(num amount) => t(
        tk: 'Tassykla — $amount TMT',
        ru: 'Подтвердить — $amount TMT',
        tr: 'Onayla — $amount TMT',
      );
  static String get topUpBalance => t(tk: 'Balans doldur', ru: 'Пополнить баланс', tr: 'Bakiye yükle');
  static String get payNow => t(tk: 'Töle', ru: 'Оплатить', tr: 'Öde');
  static String get close => t(tk: 'Ýap', ru: 'Закрыть', tr: 'Kapat');

  // subscription_screen.dart
  static String get planMonthly => t(tk: 'Aýlyk', ru: 'Месячный', tr: 'Aylık');
  static String get plan3Months => t(tk: '3 Aýlyk', ru: '3 месяца', tr: '3 Aylık');
  static String get plan6Months => t(tk: '6 Aýlyk', ru: '6 месяцев', tr: '6 Aylık');
  static String get planYearly => t(tk: 'Ýyllyk', ru: 'Годовой', tr: 'Yıllık');
  /// Fallback label for any `month_count` the 4 named getters above don't
  /// cover — keeps a future/unexpected tariff length from the backend from
  /// showing up with no label at all.
  static String planMonthsGeneric(int months) => t(tk: '$months aýlyk', ru: '$months месяцев', tr: '$months aylık');
  static String get tariffsLoadError => t(
        tk: 'Planlar ýüklenmedi',
        ru: 'Не удалось загрузить планы',
        tr: 'Planlar yüklenemedi',
      );
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');
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
        tk: '$amount TMT — Abuna bol',
        ru: '$amount TMT — Оформить подписку',
        tr: '$amount TMT — Abone ol',
      );
  static String get mostPopular => t(tk: 'Iň meşhur', ru: 'Самый популярный', tr: 'En popüler');
  static String subscriptionActivated(String planName) => t(
        tk: '$planName abunalyk işjeňleşdirildi',
        ru: 'Подписка «$planName» активирована',
        tr: '$planName aboneliği etkinleştirildi',
      );
  // widgets/subscription_success_dialog.dart
  static String get subscriptionSuccessTitle => t(tk: 'Gutlaýarys!', ru: 'Поздравляем!', tr: 'Tebrikler!');
  static String get subscriptionSuccessCta => t(tk: 'Okap başlaýyn', ru: 'Начать читать', tr: 'Okumaya başla');
  static String get activeSubscription => t(tk: 'Işjeň abunalyk', ru: 'Активная подписка', tr: 'Aktif abonelik');
  static String activeUntil(String date) => t(tk: '$date çenli güýjünde', ru: 'Действует до $date', tr: '$date tarihine kadar geçerli');
  static String get renew => t(tk: 'Uzalt', ru: 'Продлить', tr: 'Yenile');
  static String get subscriptionBalanceInsufficientNote => t(
        tk: 'Balansyňyz bu meýilnamany satyn almaga ýetmeýär. Bank kartasy bilen töläp bilersiňiz.',
        ru: 'Вашего баланса недостаточно для покупки этого плана. Вы можете оплатить банковской картой.',
        tr: 'Bakiyeniz bu planı satın almaya yetmiyor. Banka kartıyla ödeyebilirsiniz.',
      );

  // widgets/bank_select_sheet.dart
  static String get payWithCard => t(tk: 'Bank kartasy bilen töle', ru: 'Оплатить банковской картой', tr: 'Banka kartıyla öde');
  static String get selectBankTitle => t(tk: 'Bank saýlaň', ru: 'Выберите банк', tr: 'Banka seçin');
  static String get banksLoadError => t(tk: 'Banklar ýüklenmedi', ru: 'Не удалось загрузить банки', tr: 'Bankalar yüklenemedi');

  // widgets/payment_method_sheet.dart
  static String get choosePaymentMethodTitle => t(tk: 'Töleg usulyny saýlaň', ru: 'Выберите способ оплаты', tr: 'Ödeme yöntemini seçin');
  static String get payWithPromoCode => t(tk: 'Promokod bilen', ru: 'По промокоду', tr: 'Promosyon koduyla');

  // balance_top_up.dart / widgets/top_up_amount_sheet.dart
  static String get topUpTitle => t(tk: 'Balansy doldur', ru: 'Пополнить баланс', tr: 'Bakiye yükle');
  static String get topUpAmountTitle => t(tk: 'Näçe TMT dolduraly?', ru: 'На какую сумму TMT пополнить?', tr: 'Ne kadar TMT yükleyelim?');
  static String get topUpAmountHint => t(tk: 'Möçberi giriziň', ru: 'Введите сумму', tr: 'Tutarı girin');
  static String get topUpContinue => t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et');

  // widgets/promo_code_sheet.dart
  static String get promoCodeTitle => t(tk: 'Promokod giriziň', ru: 'Введите промокод', tr: 'Promosyon kodu girin');
  static String get promoCodeHint => t(tk: 'Promokod', ru: 'Промокод', tr: 'Promosyon kodu');
  static String get promoCodeApply => t(tk: 'Ulan', ru: 'Применить', tr: 'Uygula');
  static String get promoCodeAppliedBalance => t(
        tk: 'Promokod ulanyldy — balansyňyz dolduryldy',
        ru: 'Промокод применён — баланс пополнен',
        tr: 'Promosyon kodu uygulandı — bakiyeniz yüklendi',
      );
}
