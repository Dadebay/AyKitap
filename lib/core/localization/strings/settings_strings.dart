import '../strings_base.dart';

/// Strings for [SettingsScreen], its language-picker sheet, and
/// [ContactUsSheet].
class SettingsStrings {
  SettingsStrings._();

  static String get title => t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar');
  static String get theme => t(tk: 'Tema', ru: 'Тема', tr: 'Tema');
  static String get themeDark => t(tk: 'Garaňky', ru: 'Тёмная', tr: 'Karanlık');
  static String get themeLight => t(tk: 'Ýagty', ru: 'Светлая', tr: 'Aydınlık');
  static String get language => t(tk: 'Dil', ru: 'Язык', tr: 'Dil');
  static String get chooseLanguage => t(tk: 'Dili saýlaň', ru: 'Выберите язык', tr: 'Dili seçin');
  static String get contactUs => t(tk: 'Biz bilen habarlaş', ru: 'Связаться с нами', tr: 'Bizimle iletişime geçin');
  static String get logout => t(tk: 'Çykmak', ru: 'Выйти', tr: 'Çıkış yap');
  static String get logoutTitle => t(tk: 'Hasapdan çykmak isleýärsiňizmi?', ru: 'Выйти из аккаунта?', tr: 'Hesaptan çıkmak istiyor musunuz?');
  static String get logoutBody => t(
        tk: 'Täzeden girmek üçin telefon belgiňizi tassyklamaly bolarsyňyz.',
        ru: 'Чтобы войти снова, вам нужно будет подтвердить номер телефона.',
        tr: 'Tekrar giriş yapmak için telefon numaranızı doğrulamanız gerekecek.',
      );
  static String get logoutConfirm => t(tk: 'Hawa, çyk', ru: 'Да, выйти', tr: 'Evet, çık');
  static String get deleteAccount => t(tk: 'Hasaby poz', ru: 'Удалить аккаунт', tr: 'Hesabı sil');
  static String get deleteAccountTitle => t(tk: 'Hasaby pozmak isleýärsiňizmi?', ru: 'Удалить аккаунт?', tr: 'Hesabı silmek istiyor musunuz?');
  static String get deleteAccountBody => t(
        tk: 'Bu amal yzyna gaýtarylmaýar. Ähli maglumatlaryňyz DB-dan pozular.',
        ru: 'Это действие необратимо. Все ваши данные будут удалены из базы данных.',
        tr: 'Bu işlem geri alınamaz. Tüm verileriniz veritabanından silinecek.',
      );
  static String get delete => t(tk: 'Poz', ru: 'Удалить', tr: 'Sil');
  static String get cancel => t(tk: 'Ýatyr', ru: 'Отмена', tr: 'Vazgeç');
  static String get appVersion => t(tk: 'Aykitap v1.0.0', ru: 'Aykitap v1.0.0', tr: 'Aykitap v1.0.0');

  // widgets/contact_us_sheet.dart
  static String get contactTelegram => t(tk: 'Telegram', ru: 'Telegram', tr: 'Telegram');
  static String get contactPhone => t(tk: 'Telefon', ru: 'Телефон', tr: 'Telefon');
  static String get contactEmail => t(tk: 'E-poçta', ru: 'Эл. почта', tr: 'E-posta');
  static String get contactPrivacyPolicy => t(
        tk: 'Gizlinlik syýasaty',
        ru: 'Политика конфиденциальности',
        tr: 'Gizlilik politikası',
      );
  static String get contactUserAgreement => t(
        tk: 'Peýdalanyjy ylalaşygy',
        ru: 'Пользовательское соглашение',
        tr: 'Kullanıcı sözleşmesi',
      );
  static String get contactLinkOpenError => t(
        tk: 'Salgyny açyp bolmady',
        ru: 'Не удалось открыть ссылку',
        tr: 'Bağlantı açılamadı',
      );
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');

  // Language picker rows show each language's own endonym (its name in
  // itself) — not translated into whatever language is currently active,
  // same as every OS/app language picker ("Русский" stays "Русский" even
  // when the UI is in Türkmen).
  static const langTurkmen = 'Türkmen';
  static const langRussian = 'Русский';
  static const langTurkish = 'Türk';
}
