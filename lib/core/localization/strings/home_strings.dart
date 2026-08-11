import '../strings_base.dart';

/// Strings for [HomeScreen] and its section rows / cards.
class HomeStrings {
  HomeStrings._();

  static String get welcomePrefix => t(tk: 'Hoşgeldin, ', ru: 'Добро пожаловать, ', tr: 'Hoş geldin, ');

  // Placeholder shown in the header while the real name is still loading
  // asynchronously from the session.
  static String get defaultReaderName => t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu');

  // Reused across every collection section row — same exact "see all"
  // label everywhere it appears.
  static String get seeAll => t(tk: 'Ählisini gör', ru: 'Смотреть все', tr: 'Tümünü gör');

  // The `card_type: "card_2"` collection card's "see more" button.
  static String get seeMore => t(tk: 'Has köp', ru: 'Больше', tr: 'Daha fazla');

  static String get bannerLinkOpenError => t(
        tk: 'Salgyny açyp bolmady',
        ru: 'Не удалось открыть ссылку',
        tr: 'Bağlantı açılamadı',
      );

  static String get reloadTitle => t(
        tk: 'Mazmun ýüklenmedi',
        ru: 'Не удалось загрузить содержимое',
        tr: 'İçerik yüklenemedi',
      );
  static String get reloadBody => t(
        tk: 'Internet baglanyşygyňyzy barlap, täzeden synanyşyň.',
        ru: 'Проверьте подключение к интернету и попробуйте ещё раз.',
        tr: 'İnternet bağlantınızı kontrol edip yeniden deneyin.',
      );
  static String get reload => t(
        tk: 'Täzeden synanyş',
        ru: 'Повторить',
        tr: 'Yenile',
      );
}
