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
      tk: 'Biz bilen habarlaşyñ',
      ru: 'Связаться с нами',
      tr: 'Bizimle iletişime geçin',
      en: 'Contact us');
  static String get storeSubscription => t(
      tk: 'Store abunalygy',
      ru: 'Подписка через магазин',
      tr: 'Mağaza aboneliği',
      en: 'Store subscription');
  static String get storeSubscriptionActive =>
      t(tk: 'Işjeň', ru: 'Активна', tr: 'Aktif', en: 'Active');
  static String get storeSubscriptionInactive =>
      t(tk: 'Işjeň däl', ru: 'Не активна', tr: 'Aktif değil', en: 'Not active');
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

  /// Read from the installed build rather than written here — the literal
  /// this replaced still said v1.0.0 several releases after it stopped being
  /// true, which is what a hand-maintained version string always ends up
  /// doing. [build] is the build number, useful when two uploads share a
  /// version.
  static String appVersion(String version, String build) =>
      'Aykitap v$version ($build)';

  // ── New version available (see AppUpdateService / UpdateAvailableSheet) ──
  static String get updateTitle => t(
      tk: 'Täze wersiýa çykdy',
      ru: 'Вышла новая версия',
      tr: 'Yeni sürüm çıktı',
      en: 'A new version is out');

  /// The version numbers themselves are no longer spelled out in a sentence:
  /// the sheet shows them as a "1.1.5 → 1.2.1" pair, which is read at a
  /// glance and does not need translating. This line says what the sentence
  /// could not — why the reader would want it.
  static String get updateSubtitle => t(
        tk: 'Täzelenmede düzedişler we gowulaşdyrmalar bar. '
            'Täzelemek bir minutdan az wagt alýar.',
        ru: 'В обновлении — исправления и улучшения. '
            'Обновление займёт меньше минуты.',
        tr: 'Güncellemede düzeltmeler ve iyileştirmeler var. '
            'Güncelleme bir dakikadan kısa sürer.',
        en: 'This update brings fixes and improvements. '
            'It takes less than a minute.',
      );

  /// Caption over the version the reader is running now.
  static String get updateInstalledLabel =>
      t(tk: 'Sizde', ru: 'У вас', tr: 'Sizde', en: 'You have');

  /// Caption over the version waiting on the store.
  static String get updateStoreLabel =>
      t(tk: 'Täze', ru: 'Новая', tr: 'Yeni', en: 'New');
  static String get updateNow =>
      t(tk: 'Täzele', ru: 'Обновить', tr: 'Güncelle', en: 'Update');
  static String get updateLater =>
      t(tk: 'Soňra', ru: 'Позже', tr: 'Sonra', en: 'Later');

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
