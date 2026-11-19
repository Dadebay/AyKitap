import '../strings_base.dart';

/// Strings for [HomeScreen] and its section rows / cards.
class HomeStrings {
  HomeStrings._();

  static String get dailyReadingGoalTitle => t(
      tk: 'Şu gün 15 minut oka',
      ru: 'Читайте 15 минут сегодня',
      tr: 'Bugün 15 dakika oku',
      en: 'Read for 15 minutes today');
  static String get dailyReadingGoalLabel => t(
      tk: 'Şu günki okalyş',
      ru: 'Чтение сегодня',
      tr: 'Bugünkü okuma',
      en: 'Today’s reading');
  static String get dailyReadingGoalHint => t(
      tk: 'Azajyk okamak hem öňe gidişlikdir',
      ru: 'Даже немного чтения — это прогресс',
      tr: 'Kısa bir okuma bile ilerlemedir',
      en: 'Even a short read moves you forward');
  static String get dailyReadingGoalDone => t(
      tk: 'Şu günki maksadyňa ýetdiň!',
      ru: 'Цель на сегодня достигнута!',
      tr: 'Bugünkü hedefine ulaştın!',
      en: 'You reached today’s goal!');
  static String get minutesShort =>
      t(tk: 'min', ru: 'мин', tr: 'dk', en: 'min');
  static String get daysShort => t(tk: 'gün', ru: 'дн.', tr: 'gün', en: 'days');
  static String get continueReading =>
      t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et', en: 'Continue');

  static String get welcomePrefix => t(
      tk: 'Hoş geldiñ, ',
      ru: 'Добро пожаловать, ',
      tr: 'Hoş geldin, ',
      en: 'Welcome, ');

  // Placeholder shown in the header while the real name is still loading
  // asynchronously from the session.
  static String get defaultReaderName =>
      t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu', en: 'Reader');

  // Reused across every collection section row — same exact "see all"
  // label everywhere it appears.
  static String get seeAll => t(
      tk: 'Ählisini gör', ru: 'Смотреть все', tr: 'Tümünü gör', en: 'See all');

  // The `card_type: "card_2"` collection card's "see more" button.
  static String get seeMore =>
      t(tk: 'Has köp', ru: 'Больше', tr: 'Daha fazla', en: 'See more');

  static String get bannerLinkOpenError => t(
        tk: 'Salgyny açyp bolmady',
        ru: 'Не удалось открыть ссылку',
        tr: 'Bağlantı açılamadı',
        en: 'Couldn\'t open the link',
      );

  static String get reloadTitle => t(
        tk: 'Mazmun ýüklenmedi',
        ru: 'Не удалось загрузить содержимое',
        tr: 'İçerik yüklenemedi',
        en: 'Content couldn\'t load',
      );
  static String get reloadBody => t(
        tk: 'Internet baglanyşygyňyzy barlap, täzeden synanyşyň.',
        ru: 'Проверьте подключение к интернету и попробуйте ещё раз.',
        tr: 'İnternet bağlantınızı kontrol edip yeniden deneyin.',
        en: 'Check your internet connection and try again.',
      );
  static String get reload => t(
        tk: 'Täzeden synanyş',
        ru: 'Повторить',
        tr: 'Yenile',
        en: 'Retry',
      );

  static String get offlineLibraryReady => t(
        tk: 'Offline kitaphanaňyz taýýar',
        ru: 'Ваша офлайн-библиотека готова',
        tr: 'Çevrimdışı kitaplığınız hazır',
        en: 'Your offline library is ready',
      );

  static String get connectionRestored => t(
        tk: 'Baglanyşyk dikeldildi',
        ru: 'Соединение восстановлено',
        tr: 'Bağlantı yeniden kuruldu',
        en: 'You\'re back online',
      );
}
