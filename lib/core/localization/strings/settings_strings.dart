import '../strings_base.dart';

/// Strings for [SettingsScreen], its language-picker sheet, and
/// [ContactUsSheet].
class SettingsStrings {
  SettingsStrings._();

  static String get title =>
      t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar', en: 'Settings');
  static String get theme => t(tk: 'Tema', ru: 'Тема', tr: 'Tema', en: 'Theme');
  static String get themeDark =>
      t(tk: 'Garaňky', ru: 'Тёмная', tr: 'Karanlık', en: 'Dark');
  static String get themeLight =>
      t(tk: 'Ýagty', ru: 'Светлая', tr: 'Aydınlık', en: 'Light');
  static String get language =>
      t(tk: 'Dil', ru: 'Язык', tr: 'Dil', en: 'Language');
  static String get chooseLanguage => t(
      tk: 'Dili saýlaň',
      ru: 'Выберите язык',
      tr: 'Dili seçin',
      en: 'Choose a language');
  static String get contactUs => t(
      tk: 'Biz bilen habarlaş',
      ru: 'Связаться с нами',
      tr: 'Bizimle iletişime geçin',
      en: 'Contact us');
  static String get logout =>
      t(tk: 'Çykmak', ru: 'Выйти', tr: 'Çıkış yap', en: 'Log out');
  static String get logoutTitle => t(
      tk: 'Hasapdan çykmak isleýärsiňizmi?',
      ru: 'Выйти из аккаунта?',
      tr: 'Hesaptan çıkmak istiyor musunuz?',
      en: 'Log out of your account?');
  static String get logoutBody => t(
        tk: 'Täzeden girmek üçin telefon belgiňizi tassyklamaly bolarsyňyz.',
        ru: 'Чтобы войти снова, вам нужно будет подтвердить номер телефона.',
        tr: 'Tekrar giriş yapmak için telefon numaranızı doğrulamanız gerekecek.',
        en: 'You\'ll need to verify your phone number to sign in again.',
      );
  static String get logoutConfirm =>
      t(tk: 'Hawa, çyk', ru: 'Да, выйти', tr: 'Evet, çık', en: 'Yes, log out');
  static String get deleteAccount => t(
      tk: 'Hasaby poz',
      ru: 'Удалить аккаунт',
      tr: 'Hesabı sil',
      en: 'Delete account');
  static String get deleteAccountTitle => t(
      tk: 'Hasaby pozmak isleýärsiňizmi?',
      ru: 'Удалить аккаунт?',
      tr: 'Hesabı silmek istiyor musunuz?',
      en: 'Delete your account?');
  static String get deleteAccountBody => t(
        tk: 'Bu amal yzyna gaýtarylmaýar. Ähli maglumatlaryňyz DB-dan pozular.',
        ru: 'Это действие необратимо. Все ваши данные будут удалены из базы данных.',
        tr: 'Bu işlem geri alınamaz. Tüm verileriniz veritabanından silinecek.',
        en: 'This action can\'t be undone. All your data will be deleted from the database.',
      );
  static String get delete =>
      t(tk: 'Poz', ru: 'Удалить', tr: 'Sil', en: 'Delete');
  static String get cancel =>
      t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç', en: 'Cancel');
  static String get appVersion => t(
      tk: 'Aykitap v1.0.0',
      ru: 'Aykitap v1.0.0',
      tr: 'Aykitap v1.0.0',
      en: 'Aykitap v1.0.0');

  // widgets/contact_us_sheet.dart
  static String get contactTelegram =>
      t(tk: 'Telegram', ru: 'Telegram', tr: 'Telegram', en: 'Telegram');
  static String get contactPhone =>
      t(tk: 'Telefon', ru: 'Телефон', tr: 'Telefon', en: 'Phone');
  static String get contactEmail =>
      t(tk: 'E-poçta', ru: 'Эл. почта', tr: 'E-posta', en: 'Email');
  static String get contactPrivacyPolicy => t(
        tk: 'Gizlinlik syýasaty',
        ru: 'Политика конфиденциальности',
        tr: 'Gizlilik politikası',
        en: 'Privacy policy',
      );
  static String get contactUserAgreement => t(
        tk: 'Peýdalanyjy ylalaşygy',
        ru: 'Пользовательское соглашение',
        tr: 'Kullanıcı sözleşmesi',
        en: 'User agreement',
      );
  static String get contactLinkOpenError => t(
        tk: 'Salgyny açyp bolmady',
        ru: 'Не удалось открыть ссылку',
        tr: 'Bağlantı açılamadı',
        en: 'Couldn\'t open the link',
      );
  static String get retry => t(
      tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');

  // Language picker rows show each language's own endonym (its name in
  // itself) — not translated into whatever language is currently active,
  // same as every OS/app language picker ("Русский" stays "Русский" even
  // when the UI is in Türkmen).
  static const langTurkmen = 'Türkmen';
  static const langRussian = 'Русский';
  static const langTurkish = 'Türk';
  static const langEnglish = 'English';
}
