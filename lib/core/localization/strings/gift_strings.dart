import '../strings_base.dart';

/// Strings for [SendGiftSheet] and its entry row on [ProfileScreen].
class GiftStrings {
  GiftStrings._();

  static String get entryTitle => t(
      tk: 'Sowgat iber',
      ru: 'Отправить подарок',
      tr: 'Hediye gönder',
      en: 'Send a gift');
  static String get sheetTitle => t(
      tk: 'Sowgat iber',
      ru: 'Отправить подарок',
      tr: 'Hediye gönder',
      en: 'Send a gift');
  static String get sheetSubtitle => t(
        tk: 'Dostlaryňyzy begendiriň — Aýkitap-da hasaby bar ulanyjynyň balansyna sowgat iberiň.',
        ru: 'Порадуйте друзей — отправьте подарок на баланс зарегистрированного пользователя Aýkitap.',
        tr: 'Arkadaşlarınızı sevindirin — Aýkitap\'ta hesabı olan kullanıcının bakiyesine hediye gönderin.',
        en: 'Make a friend\'s day — send a gift to the balance of any registered Aýkitap user.',
      );
  static String get amountLabel => t(
      tk: 'Möçberi (TMT)',
      ru: 'Сумма (TMT)',
      tr: 'Tutar (TMT)',
      en: 'Amount (TMT)');
  static String get amountHint => t(
      tk: 'Möçberi giriziň',
      ru: 'Введите сумму',
      tr: 'Tutarı girin',
      en: 'Enter amount');
  static String get phoneLabel => t(
        tk: 'Alyjynyň telefon belgisi',
        ru: 'Номер телефона получателя',
        tr: 'Alıcının telefon numarası',
        en: 'Recipient\'s phone number',
      );
  static String get checkingUser => t(
      tk: 'Barlanýar...',
      ru: 'Проверяем...',
      tr: 'Kontrol ediliyor...',
      en: 'Checking...');
  static String get userFound => t(
      tk: 'Ulanyjy tapyldy',
      ru: 'Пользователь найден',
      tr: 'Kullanıcı bulundu',
      en: 'User found');
  static String get userNotFound => t(
        tk: 'Bu belgi bilen ulanyjy tapylmady',
        ru: 'Пользователь с этим номером не найден',
        tr: 'Bu numarayla kullanıcı bulunamadı',
        en: 'No user found with this number',
      );
  static String get userCheckFailed => t(
        tk: 'Ulanyjyny barlap bolmady',
        ru: 'Не удалось проверить пользователя',
        tr: 'Kullanıcı kontrol edilemedi',
        en: 'Couldn\'t check the user',
      );
  static String get send =>
      t(tk: 'Iber', ru: 'Отправить', tr: 'Gönder', en: 'Send');
  static String sendWithAmount(num amount) => t(
        tk: 'Iber — $amount TMT',
        ru: 'Отправить — $amount TMT',
        tr: 'Gönder — $amount TMT',
        en: 'Send — $amount TMT',
      );
  static String get sentSuccess => t(
      tk: 'Sowgat iberildi!',
      ru: 'Подарок отправлен!',
      tr: 'Hediye gönderildi!',
      en: 'Gift sent!');
  static String sentDescription(num amount) => t(
        tk: '$amount TMT alyjynyň balansyna geçirildi.',
        ru: '$amount TMT переведено на баланс получателя.',
        tr: '$amount TMT alıcının bakiyesine aktarıldı.',
        en: '$amount TMT was transferred to the recipient\'s balance.',
      );
  static String get successCta =>
      t(tk: 'Gowy', ru: 'Готово', tr: 'Tamam', en: 'Done');
}
