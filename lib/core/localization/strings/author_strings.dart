import '../strings_base.dart';

/// Strings for [AuthorScreen] and [CatalogAuthorDetailScreen].
class AuthorStrings {
  AuthorStrings._();

  /// Generic fallback badge on [CatalogAuthorCard] when the caller has no
  /// `book_count` for this author (Home's collection row — only Search's
  /// `GET /authors/search` returns a count) — so the card's info area always
  /// has something to show instead of sitting empty.
  static String get authorLabel => t(tk: 'Awtor', ru: 'Автор', tr: 'Yazar', en: 'Author');

  static String booksCountLabel(int count) => t(tk: '$count kitap', ru: '$count книг', tr: '$count kitap', en: '$count books');
  static String get showLess => t(tk: 'Az görkez', ru: 'Свернуть', tr: 'Daha az göster', en: 'Show less');
  static String get readMore => t(tk: 'Dowamyny oka', ru: 'Читать далее', tr: 'Devamını oku', en: 'Read more');
  static String get allBooks => t(tk: 'Ähli kitaplary', ru: 'Все книги', tr: 'Tüm kitapları', en: 'All books');
  static String pagesLabel(int count) => t(tk: '$count', ru: '$count', tr: '$count ', en: '$count');

  // Sort control next to `allBooks` — client-side, over the already-fetched
  // author book list (see `_CatalogAuthorDetailScreenState._sortBooks`).
  static String get sortAZ => t(tk: 'A-Z', ru: 'A-Z', tr: 'A-Z', en: 'A-Z');
  static String get sortByDate => t(tk: 'Senesi boýunça', ru: 'По дате', tr: 'Tarihe göre', en: 'By date');

  // catalog_author_detail_screen.dart
  static String get loadError => t(tk: 'Awtor ýüklenmedi', ru: 'Не удалось загрузить автора', tr: 'Yazar yüklenemedi', en: 'Author couldn\'t load');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');
  static String get noBooksYetTitle => t(
        tk: 'Bu Awtoryň entäk kitaby ýok',
        ru: 'У этого автора пока нет книг',
        tr: 'Bu yazarın henüz kitabı yok',
        en: 'This author has no books yet',
      );
  static String get noBooksYetSubtitle => t(
        tk: 'Täze kitap goşulsa, ol şu ýerde peýda bolar.',
        ru: 'Когда появится новая книга, она будет показана здесь.',
        tr: 'Yeni bir kitap eklendiğinde burada görünecek.',
        en: 'When a new book is added, it will show up here.',
      );
}
