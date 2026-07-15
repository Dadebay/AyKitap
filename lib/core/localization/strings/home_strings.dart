import '../strings_base.dart';

/// Strings for [HomeScreen] and its section rows / cards.
class HomeStrings {
  HomeStrings._();

  static String get welcomePrefix => t(tk: 'Hoşgeldin, ', ru: 'Добро пожаловать, ', tr: 'Hoş geldin, ');

  // Placeholder shown in the header while the real name is still loading
  // asynchronously from the session.
  static String get defaultReaderName => t(tk: 'Okyjy', ru: 'Читатель', tr: 'Okuyucu');

  static String get popularBooks => t(tk: 'Popüler Kitaplar', ru: 'Популярные книги', tr: 'Popüler Kitaplar');

  // Reused across every genre section row and the authors row — same exact
  // "see all" label everywhere it appears.
  static String get seeAll => t(tk: 'Ählisini gör', ru: 'Смотреть все', tr: 'Tümünü gör');

  static String get collections => t(tk: 'Kolleksiýalar', ru: 'Коллекции', tr: 'Koleksiyonlar');

  static String get series => t(tk: 'Seriýalar', ru: 'Серии', tr: 'Seriler');

  // The series row uses a shorter "All" label instead of "See all".
  static String get seriesSeeAll => t(tk: 'Ählisi', ru: 'Все', tr: 'Tümü');

  static String get authors => t(tk: 'Ýazarlar', ru: 'Авторы', tr: 'Yazarlar');

  static String get rankTagTop100 => t(tk: '🔥 Ilkinji 100', ru: '🔥 Первые 100', tr: '🔥 İlk 100');
  static String get rankSubtitleTop100 => t(tk: 'Iň köp okalan kitaplar', ru: 'Самые читаемые книги', tr: 'En çok okunan kitaplar');

  static String get rankTagEditorsChoice => t(tk: '⭐ Redaktoryň saýlawy', ru: '⭐ Выбор редактора', tr: '⭐ Editörün seçimi');
  static String get rankSubtitleEditorsChoice => t(
        tk: 'Bize ýaraýan iň gowy eserler',
        ru: 'Лучшие произведения, которые нам нравятся',
        tr: 'Beğendiğimiz en iyi eserler',
      );

  static String get rankTagNewlyAdded => t(tk: '🆕 Täze goşulanlar', ru: '🆕 Новые поступления', tr: '🆕 Yeni eklenenler');
  static String get rankSubtitleNewlyAdded => t(
        tk: 'Bu hepde goşulan kitaplar',
        ru: 'Книги, добавленные на этой неделе',
        tr: 'Bu hafta eklenen kitaplar',
      );

  static String get seeMore => t(tk: 'Has köp', ru: 'Больше', tr: 'Daha fazla');

  /// "$count kitap" — Russian needs proper plural-form agreement for
  /// "книга" (книга / книги / книг) since it doesn't collapse to one form
  /// the way Turkmen/Turkish counts do.
  static String bookCount(int count) => t(
        tk: '$count kitap',
        ru: '$count ${_ruBookWord(count)}',
        tr: '$count kitap',
      );

  static String _ruBookWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'книг';
    if (mod10 == 1) return 'книга';
    if (mod10 >= 2 && mod10 <= 4) return 'книги';
    return 'книг';
  }

  static String get banner1Title => t(tk: 'Isleýän Wagtyň,\nIsleýän Ýeriňde', ru: 'Когда угодно,\nГде угодно', tr: 'İstediğin An,\nİstediğin Yerde');
  static String get banner1Subtitle => t(
        tk: 'Abuna boluň we ähli kitaplary çäksiz okaň',
        ru: 'Оформите подписку и читайте все книги без ограничений',
        tr: 'Abone olun ve tüm kitapları sınırsız okuyun',
      );

  static String get banner2Title => t(tk: 'Täze Kitaplar\nHer Hepde', ru: 'Новые книги\nКаждую неделю', tr: 'Her Hafta\nYeni Kitaplar');
  static String get banner2Subtitle => t(
        tk: 'Iň soňky çykan eserleri ilkinji bolup okaň',
        ru: 'Читайте новинки первыми',
        tr: 'En son çıkan eserleri ilk siz okuyun',
      );

  static String get banner3Title => t(tk: '20% Arzanladyş\nÝyllyk Abuna', ru: 'Скидка 20%\nНа годовую подписку', tr: '%20 İndirim\nYıllık Abonelikte');
  static String get banner3Subtitle => t(
        tk: 'Diňe şu hepde — pursatdan peýdalanyň',
        ru: 'Только на этой неделе — успейте воспользоваться',
        tr: 'Sadece bu hafta — fırsatı kaçırmayın',
      );

  static String get banner4Title => t(tk: 'Kitaphanaňyz\nElmydama Ýanyňyzda', ru: 'Ваша библиотека\nВсегда с вами', tr: 'Kitaplığınız\nHer Zaman Yanınızda');
  static String get banner4Subtitle => t(
        tk: 'Ýükläň we internetsiz islendik ýerde okaň',
        ru: 'Скачивайте и читайте где угодно без интернета',
        tr: 'İndirin ve internetsiz istediğiniz yerde okuyun',
      );
}
