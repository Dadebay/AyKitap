import '../strings_base.dart';

/// Strings for [BookPurchaseScreen] and [SubscriptionScreen] (payment module).
class PaymentStrings {
  PaymentStrings._();

  // payment_webview_screen.dart
  static String get paymentPageTitle =>
      t(tk: 'Töleg', ru: 'Оплата', tr: 'Ödeme', en: 'Payment');

  // book_purchase_screen.dart
  static String get purchaseTitle =>
      t(tk: 'Satyn alyş', ru: 'Покупка', tr: 'Satın alma', en: 'Purchase');
  static String purchasedSnackbar(String title) => t(
        tk: '«$title» satyn alyndy',
        ru: '«$title» приобретена',
        tr: '«$title» satın alındı',
        en: '“$title” purchased',
      );
  static String get balanceNotEnough => t(
      tk: 'Balans ýeterlik däl',
      ru: 'Недостаточно средств на балансе',
      tr: 'Bakiye yetersiz',
      en: 'Insufficient balance');
  static String get bookPrice => t(
      tk: 'Kitabyň bahasy',
      ru: 'Цена книги',
      tr: 'Kitabın fiyatı',
      en: 'Book price');
  static String get yourBalance => t(
      tk: 'Balansyňyz', ru: 'Ваш баланс', tr: 'Bakiyeniz', en: 'Your balance');
  static String get afterPurchase => t(
      tk: 'Satyn alandan soň',
      ru: 'После покупки',
      tr: 'Satın aldıktan sonra',
      en: 'After purchase');
  static String get notEnough => t(
      tk: 'Ýeterlik däl', ru: 'Недостаточно', tr: 'Yetersiz', en: 'Not enough');

  /// Currency code is deliberately the same in every language and screen.
  static String manat(num amount) => '$amount TMT';
  static String get balanceInsufficientNote => t(
        tk: 'Balansyňyz bu kitaby almaga ýetmeýär. Balansy dolduryň.',
        ru: 'Вашего баланса недостаточно для покупки этой книги. Пополните баланс.',
        tr: 'Bakiyeniz bu kitabı almaya yetmiyor. Bakiyenizi yükleyin.',
        en: 'Your balance isn\'t enough to buy this book. Top up your balance.',
      );

  /// Exact shortfall for [InsufficientBalanceDialog] — how much more the
  /// balance needs before this purchase goes through.
  static String balanceShortfall(num amount) => t(
        tk: 'Bu kitaby almak üçin ýene $amount TMT gerek. Balansy dolduryň.',
        ru: 'Для покупки этой книги не хватает $amount TMT. Пополните баланс.',
        tr: 'Bu kitabı almak için $amount TMT daha gerekli. Bakiyenizi yükleyin.',
        en: 'You need $amount TMT more to buy this book. Top up your balance.',
      );
  static String get booksOnlyInApp => t(
        tk: 'Kitaplar diňe programmada okalýar — telefona ýüklenmeýär.',
        ru: 'Книги читаются только в приложении — на телефон не скачиваются.',
        tr: 'Kitaplar yalnızca uygulama içinde okunur — telefona indirilmez.',
        en: 'Books are read only in the app — they aren\'t downloaded to your phone.',
      );
  static String confirmWithPrice(num amount) => t(
        tk: 'Tassykla — $amount TMT',
        ru: 'Подтвердить — $amount TMT',
        tr: 'Onayla — $amount TMT',
        en: 'Confirm — $amount TMT',
      );
  static String get topUpBalance => t(
      tk: 'Balans doldur',
      ru: 'Пополнить баланс',
      tr: 'Bakiye yükle',
      en: 'Top up balance');
  static String get payNow =>
      t(tk: 'Töle', ru: 'Оплатить', tr: 'Öde', en: 'Pay now');
  static String get close =>
      t(tk: 'Ýap', ru: 'Закрыть', tr: 'Kapat', en: 'Close');

  // subscription_screen.dart
  static String get planMonthly =>
      t(tk: 'Aýlyk', ru: 'Месячный', tr: 'Aylık', en: 'Monthly');
  static String get plan3Months =>
      t(tk: '3 Aýlyk', ru: '3 месяца', tr: '3 Aylık', en: '3 Months');
  static String get plan6Months =>
      t(tk: '6 Aýlyk', ru: '6 месяцев', tr: '6 Aylık', en: '6 Months');
  static String get planYearly =>
      t(tk: 'Ýyllyk', ru: 'Годовой', tr: 'Yıllık', en: 'Yearly');

  /// Fallback label for any `month_count` the 4 named getters above don't
  /// cover — keeps a future/unexpected tariff length from the backend from
  /// showing up with no label at all.
  static String planMonthsGeneric(int months) => t(
      tk: '$months aýlyk',
      ru: '$months месяцев',
      tr: '$months aylık',
      en: '$months months');
  static String get tariffsLoadError => t(
        tk: 'Planlar ýüklenmedi',
        ru: 'Не удалось загрузить планы',
        tr: 'Planlar yüklenemedi',
        en: 'Plans couldn\'t load',
      );
  static String get retry => t(
      tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');
  static String get subscriptionTitle =>
      t(tk: 'Abunalyk', ru: 'Подписка', tr: 'Abonelik', en: 'Subscription');
  static String get unlimitedAccessTitle => t(
        tk: 'Ähli kitaplara çäksiz giriş',
        ru: 'Неограниченный доступ ко всем книгам',
        tr: 'Tüm kitaplara sınırsız erişim',
        en: 'Unlimited access to every book',
      );
  static String get unlimitedAccessSubtitle => t(
        tk: 'Abunalyk dowam edýänçä ähli kitaplary okap bilersiňiz.',
        ru: 'Пока подписка активна, вы можете читать все книги.',
        tr: 'Abonelik devam ettiği sürece tüm kitapları okuyabilirsiniz.',
        en: 'You can read every book for as long as your subscription is active.',
      );
  static String get chooseYourPlan => t(
        tk: 'Özüňize laýyk plany saýlaň',
        ru: 'Выберите подходящий план',
        tr: 'Size uygun planı seçin',
        en: 'Choose the plan for you',
      );
  static String get chooseYourPlanSubtitle => t(
        tk: 'Uzak möhletli plan bilen has köp tygşytlaň',
        ru: 'Экономьте больше с долгосрочным планом',
        tr: 'Uzun dönemli planla daha fazla tasarruf edin',
        en: 'Save more with a longer plan',
      );
  static String get benefitAllBooks => t(
      tk: 'Ähli kitaplar',
      ru: 'Все книги',
      tr: 'Tüm kitaplar',
      en: 'Every book');
  static String get benefitNoExtraPurchase => t(
        tk: 'Aýratyn töleg ýok',
        ru: 'Без доплат',
        tr: 'Ek satın alma yok',
        en: 'No extra purchase',
      );
  static String get benefitKeepProgress => t(
        tk: 'Progresiňiz saklanýar',
        ru: 'Прогресс сохраняется',
        tr: 'İlerlemeniz korunur',
        en: 'Progress stays synced',
      );
  static String monthlyEquivalent(num amount) => t(
        tk: 'Aýda $amount TMT',
        ru: '$amount TMT в месяц',
        tr: 'Aylık $amount TMT',
        en: '$amount TMT/month',
      );
  static String planSelectedMock(String planName) => t(
        tk: '$planName plan saýlandy (mock)',
        ru: 'Выбран план $planName (демо)',
        tr: '$planName planı seçildi (mock)',
        en: '$planName plan selected (mock)',
      );
  static String subscribeWithPrice(num amount) => t(
        tk: '$amount TMT — Abuna bol',
        ru: '$amount TMT — Оформить подписку',
        tr: '$amount TMT — Abone ol',
        en: '$amount TMT — Subscribe',
      );
  static String get mostPopular => t(
      tk: 'Iň meşhur',
      ru: 'Самый популярный',
      tr: 'En popüler',
      en: 'Most popular');
  static String subscriptionActivated(String planName) => t(
        tk: '$planName abunalyk işjeňleşdirildi',
        ru: 'Подписка «$planName» активирована',
        tr: '$planName aboneliği etkinleştirildi',
        en: '$planName subscription activated',
      );
  // widgets/subscription_success_dialog.dart
  static String get subscriptionSuccessTitle => t(
      tk: 'Gutlaýarys!', ru: 'Поздравляем!', tr: 'Tebrikler!', en: 'Congrats!');
  static String get subscriptionSuccessCta => t(
      tk: 'Okap başlaýyn',
      ru: 'Начать читать',
      tr: 'Okumaya başla',
      en: 'Start reading');
  static String get activeSubscription => t(
      tk: 'Işjeň abunalyk',
      ru: 'Активная подписка',
      tr: 'Aktif abonelik',
      en: 'Active subscription');
  static String activeUntil(String date) => t(
      tk: '$date çenli güýjünde',
      ru: 'Действует до $date',
      tr: '$date tarihine kadar geçerli',
      en: 'Valid until $date');
  static String get renew =>
      t(tk: 'Uzalt', ru: 'Продлить', tr: 'Yenile', en: 'Renew');

  // widgets/subscription_required_dialog.dart
  static String get subscriptionRequiredTitle => t(
      tk: 'Abunalyk gerek',
      ru: 'Требуется подписка',
      tr: 'Abonelik gerekli',
      en: 'Subscription required');
  static String get subscriptionRequiredBody => t(
        tk: 'Bu kitaby okamak üçin abuna bolup ähli kitaplara giriş gazanyp bilersiňiz, ýa-da diňe şu kitaby satyn alyp bilersiňiz.',
        ru: 'Чтобы читать эту книгу, оформите подписку и получите доступ ко всем книгам, либо купите только эту книгу.',
        tr: 'Bu kitabı okumak için abone olup tüm kitaplara erişebilir, ya da yalnızca bu kitabı satın alabilirsiniz.',
        en: 'To read this book, you can subscribe for access to every book, or just buy this one.',
      );
  static String get subscribeCta => t(
      tk: 'Abuna bol',
      ru: 'Оформить подписку',
      tr: 'Abone ol',
      en: 'Subscribe');
  static String get subscriptionBalanceInsufficientNote => t(
        tk: 'Balansyňyz bu meýilnamany satyn almaga ýetmeýär. Bank kartasy bilen töläp bilersiňiz.',
        ru: 'Вашего баланса недостаточно для покупки этого плана. Вы можете оплатить банковской картой.',
        tr: 'Bakiyeniz bu planı satın almaya yetmiyor. Banka kartıyla ödeyebilirsiniz.',
        en: 'Your balance isn\'t enough to buy this plan. You can pay with a bank card.',
      );

  // widgets/bank_select_sheet.dart
  static String get payWithCard => t(
      tk: 'Bank kartasy bilen töle',
      ru: 'Оплатить банковской картой',
      tr: 'Banka kartıyla öde',
      en: 'Pay with a bank card');
  static String get selectBankTitle => t(
      tk: 'Bank saýlaň',
      ru: 'Выберите банк',
      tr: 'Banka seçin',
      en: 'Choose a bank');
  static String get banksLoadError => t(
      tk: 'Banklar ýüklenmedi',
      ru: 'Не удалось загрузить банки',
      tr: 'Bankalar yüklenemedi',
      en: 'Banks couldn\'t load');

  // widgets/payment_method_sheet.dart
  static String get choosePaymentMethodTitle => t(
      tk: 'Töleg usulyny saýlaň',
      ru: 'Выберите способ оплаты',
      tr: 'Ödeme yöntemini seçin',
      en: 'Choose a payment method');
  static String get payWithPromoCode => t(
      tk: 'Promokod bilen',
      ru: 'По промокоду',
      tr: 'Promosyon koduyla',
      en: 'With a promo code');

  // balance_top_up.dart / widgets/top_up_amount_sheet.dart
  static String get topUpTitle => t(
      tk: 'Balansy doldur',
      ru: 'Пополнить баланс',
      tr: 'Bakiye yükle',
      en: 'Top up balance');
  static String get topUpAmountTitle => t(
      tk: 'Näçe TMT dolduraly?',
      ru: 'На какую сумму TMT пополнить?',
      tr: 'Ne kadar TMT yükleyelim?',
      en: 'How much TMT should we add?');
  static String get topUpAmountHint => t(
      tk: 'Möçberi giriziň',
      ru: 'Введите сумму',
      tr: 'Tutarı girin',
      en: 'Enter amount');
  static String get topUpContinue =>
      t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et', en: 'Continue');

  // widgets/promo_code_sheet.dart
  static String get promoCodeTitle => t(
      tk: 'Promokod giriziň',
      ru: 'Введите промокод',
      tr: 'Promosyon kodu girin',
      en: 'Enter promo code');
  static String get promoCodeHint =>
      t(tk: 'Promokod', ru: 'Промокод', tr: 'Promosyon kodu', en: 'Promo code');
  static String get promoCodeApply =>
      t(tk: 'Ulan', ru: 'Применить', tr: 'Uygula', en: 'Apply');
  static String get promoCodeAppliedBalance => t(
        tk: 'Promokod ulanyldy — balansyňyz dolduryldy',
        ru: 'Промокод применён — баланс пополнен',
        tr: 'Promosyon kodu uygulandı — bakiyeniz yüklendi',
        en: 'Promo code applied — your balance was topped up',
      );
}
