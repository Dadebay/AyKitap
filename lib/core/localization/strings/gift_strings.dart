import '../strings_base.dart';

/// Strings for [SendGiftSheet] and its entry row on [ProfileScreen].
class GiftStrings {
  GiftStrings._();

  static String get entryTitle =>
      t(tk: 'Sowgat iber', ru: 'Отправить подарок', tr: 'Hediye gönder');
  static String get sheetTitle =>
      t(tk: 'Sowgat iber', ru: 'Отправить подарок', tr: 'Hediye gönder');
  static String get sheetSubtitle => t(
        tk: 'Dostlaryňyzy begendiriň — Aýkitap-da hasaby bar ulanyjynyň balansyna sowgat iberiň.',
        ru: 'Порадуйте друзей — отправьте подарок на баланс зарегистрированного пользователя Aýkitap.',
        tr: 'Arkadaşlarınızı sevindirin — Aýkitap\'ta hesabı olan kullanıcının bakiyesine hediye gönderin.',
      );
  static String get amountLabel =>
      t(tk: 'Möçberi (TMT)', ru: 'Сумма (TMT)', tr: 'Tutar (TMT)');
  static String get amountHint =>
      t(tk: 'Möçberi giriziň', ru: 'Введите сумму', tr: 'Tutarı girin');
  static String get phoneLabel => t(
        tk: 'Alyjynyň telefon belgisi',
        ru: 'Номер телефона получателя',
        tr: 'Alıcının telefon numarası',
      );
  static String get checkingUser =>
      t(tk: 'Barlanýar...', ru: 'Проверяем...', tr: 'Kontrol ediliyor...');
  static String get userFound => t(
      tk: 'Ulanyjy tapyldy',
      ru: 'Пользователь найден',
      tr: 'Kullanıcı bulundu');
  static String get userNotFound => t(
        tk: 'Bu belgi bilen ulanyjy tapylmady',
        ru: 'Пользователь с этим номером не найден',
        tr: 'Bu numarayla kullanıcı bulunamadı',
      );
  static String get userCheckFailed => t(
        tk: 'Ulanyjyny barlap bolmady',
        ru: 'Не удалось проверить пользователя',
        tr: 'Kullanıcı kontrol edilemedi',
      );
  static String get send => t(tk: 'Iber', ru: 'Отправить', tr: 'Gönder');
  static String sendWithAmount(num amount) => t(
        tk: 'Iber — $amount TMT',
        ru: 'Отправить — $amount TMT',
        tr: 'Gönder — $amount TMT',
      );
  static String get sentSuccess => t(
      tk: 'Sowgat iberildi!',
      ru: 'Подарок отправлен!',
      tr: 'Hediye gönderildi!');
  static String sentDescription(num amount) => t(
        tk: '$amount TMT alyjynyň balansyna geçirildi.',
        ru: '$amount TMT переведено на баланс получателя.',
        tr: '$amount TMT alıcının bakiyesine aktarıldı.',
      );
  static String get successCta => t(tk: 'Gowy', ru: 'Готово', tr: 'Tamam');
}
