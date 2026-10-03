import '../strings_base.dart';

/// Strings for [SearchScreen] (search module).
class SearchStrings {
  SearchStrings._();

  static String get title => t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama', en: 'Search');
  static String get searchHint => t(tk: 'Kitaplary, awtorlary gözlemek', ru: 'Поиск по названиям и авторам', tr: 'Kitap ismi ve yazar ara', en: 'Search titles and authors');
  static String get noResults => t(tk: 'Netije tapylmady', ru: 'Результаты не найдены', tr: 'Sonuç bulunamadı', en: 'No results found');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');

  /// The way out of an empty search: a reader who searched for something we
  /// do not have is the reader best placed to tell us it is missing, and
  /// this is the moment they care. The same request the profile's "Kitap
  /// haýyşlarym" screen sends — see [BookRequestSheet].
  static String get noResultsSuggestBody => t(
        tk: 'Aýkitapda tapmadyk kitabyňyzy bize teklip edip bilersiňiz.',
        ru: 'Вы можете предложить нам книгу, которую не нашли в Aýkitap.',
        tr: 'Aýkitap\'ta bulamadığınız kitabı bize önerebilirsiniz.',
        en: 'You can suggest a book you could not find on Aýkitap.',
      );
  static String get suggestBook => t(tk: 'Kitap teklip et', ru: 'Предложить книгу', tr: 'Kitap öner', en: 'Suggest a book');

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
