import '../strings_base.dart';

/// Strings for [SearchScreen] (search module).
class SearchStrings {
  SearchStrings._();

  static String get title => t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama');
  static String get searchHint => t(tk: 'Atlar, adamlar, bellikleri gözlemek', ru: 'Поиск по названиям, авторам, тегам', tr: 'İsim, yazar, etiket ara');
  static String get noResults => t(tk: 'Netije tapylmady', ru: 'Результаты не найдены', tr: 'Sonuç bulunamadı');
}
