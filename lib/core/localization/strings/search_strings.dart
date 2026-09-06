import '../strings_base.dart';

/// Strings for [SearchScreen] (search module).
class SearchStrings {
  SearchStrings._();

  static String get title => t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama', en: 'Search');
  static String get searchHint => t(tk: 'Kitaplary, awtorlary gözlemek', ru: 'Поиск по названиям, авторам, тегам', tr: 'İsim, yazar, etiket ara', en: 'Search titles, authors, tags');
  static String get noResults => t(tk: 'Netije tapylmady', ru: 'Результаты не найдены', tr: 'Sonuç bulunamadı', en: 'No results found');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');

  // Book/author search-mode toggle — which field the typed text matches.
  static String get searchByBook => t(tk: 'Kitap', ru: 'Книга', tr: 'Kitap', en: 'Book');
  static String get searchByAuthor => t(tk: 'Awtor', ru: 'Автор', tr: 'Yazar', en: 'Author');

  /// Shown in place of the (book-only) discover grid while Author mode has
  /// no typed query yet — `GET /authors/search` needs actual text, so there's
  /// nothing to browse before that, unlike Book mode's discover grid.
  static String get authorSearchPrompt => t(
        tk: 'Awtoryň adyny ýazyp gözläň',
        ru: 'Введите имя автора для поиска',
        tr: 'Aramak için yazar adını yazın',
        en: 'Type an author’s name to search',
      );
}
