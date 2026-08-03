import '../strings_base.dart';

/// Strings for [SearchScreen] (search module).
class SearchStrings {
  SearchStrings._();

  static String get title => t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama');
  static String get searchHint => t(tk: 'Atlar, adamlar, bellikleri gözlemek', ru: 'Поиск по названиям, авторам, тегам', tr: 'İsim, yazar, etiket ara');
  static String get noResults => t(tk: 'Netije tapylmady', ru: 'Результаты не найдены', tr: 'Sonuç bulunamadı');
  static String get retry => t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');

  // Book/author search-mode toggle — which field the typed text matches.
  static String get searchByBook => t(tk: 'Kitap', ru: 'Книга', tr: 'Kitap');
  static String get searchByAuthor => t(tk: 'Ýazar', ru: 'Автор', tr: 'Yazar');
}
