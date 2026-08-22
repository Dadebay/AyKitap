import '../strings_base.dart';

/// Strings for [AuthorScreen] and [CatalogAuthorDetailScreen].
class AuthorStrings {
  AuthorStrings._();

  static String booksCountLabel(int count) =>
      t(tk: '$count kitap', ru: '$count книг', tr: '$count kitap');
  static String get showLess =>
      t(tk: 'Az görkez', ru: 'Свернуть', tr: 'Daha az göster');
  static String get readMore =>
      t(tk: 'Dowamyny oka', ru: 'Читать далее', tr: 'Devamını oku');
  static String get allBooks =>
      t(tk: 'Ähli kitaplary', ru: 'Все книги', tr: 'Tüm kitapları');
  static String pagesLabel(int count) =>
      t(tk: '$count', ru: '$count', tr: '$count ');

  // Sort control next to `allBooks` — client-side, over the already-fetched
  // author book list (see `_CatalogAuthorDetailScreenState._sortBooks`).
  static String get sortAZ => t(tk: 'A-Z', ru: 'A-Z', tr: 'A-Z');
  static String get sortByDate =>
      t(tk: 'Senesi boýunça', ru: 'По дате', tr: 'Tarihe göre');

  // catalog_author_detail_screen.dart
  static String get loadError => t(
      tk: 'Ýazar ýüklenmedi',
      ru: 'Не удалось загрузить автора',
      tr: 'Yazar yüklenemedi');
  static String get retry =>
      t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');
  static String get noBooksYetTitle => t(
        tk: 'Bu ýazaryň entäk kitaby ýok',
        ru: 'У этого автора пока нет книг',
        tr: 'Bu yazarın henüz kitabı yok',
      );
  static String get noBooksYetSubtitle => t(
        tk: 'Täze kitap goşulsa, ol şu ýerde peýda bolar.',
        ru: 'Когда появится новая книга, она будет показана здесь.',
        tr: 'Yeni bir kitap eklendiğinde burada görünecek.',
      );
}
