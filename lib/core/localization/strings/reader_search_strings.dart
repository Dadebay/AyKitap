import '../strings_base.dart';

/// Strings for the reader's in-book search (TZ §12.3) — [SearchSheetHeader]
/// and [SearchSheetResults]. Split out of [ReaderStrings] to keep that file
/// under the 200-line limit; this section was cleanly self-contained (used
/// by exactly those two widgets), so no other call site needed touching.
class ReaderSearchStrings {
  ReaderSearchStrings._();

  static String get searchTitle => t(
      tk: 'Kitapdan gözle',
      ru: 'Поиск в книге',
      tr: 'Kitapta ara',
      en: 'Search in book');
  static String get searchHint => t(
      tk: 'Söz ýa-da jümle...',
      ru: 'Слово или фраза...',
      tr: 'Kelime veya cümle...',
      en: 'Word or phrase...');
  static String get searchNoResults => t(
      tk: 'Netije tapylmady',
      ru: 'Ничего не найдено',
      tr: 'Sonuç bulunamadı',
      en: 'No results found');
  static String get searchPrompt => t(
      tk: 'Gözlemek üçin ýazyň',
      ru: 'Введите запрос для поиска',
      tr: 'Aramak için yazın',
      en: 'Type to search');
  static String get searchSearching => t(
      tk: 'Gözlenýär...',
      ru: 'Идёт поиск...',
      tr: 'Aranıyor...',
      en: 'Searching...');
  static String get searchTooShort => t(
        tk: 'Iň azyndan 2 harp ýazyň',
        ru: 'Введите минимум 2 символа',
        tr: 'En az 2 harf yazın',
        en: 'Type at least 2 characters',
      );
  static String searchNoResultsFor(String query) => t(
        tk: '«$query» boýunça netije tapylmady',
        ru: 'По запросу «$query» ничего не найдено',
        tr: '«$query» için sonuç bulunamadı',
        en: 'No results found for “$query”',
      );

  /// Result count for the sheet's header. Russian needs the 1 / 2–4 / 5+ noun
  /// forms, so it can't be a plain interpolation; English just needs the
  /// singular/plural split.
  static String searchResultCount(int n) => t(
        tk: '$n netije',
        ru: '$n ${_ruResultNoun(n)}',
        tr: '$n sonuç',
        en: '$n ${n == 1 ? 'result' : 'results'}',
      );

  static String _ruResultNoun(int n) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'результатов';
    switch (n % 10) {
      case 1:
        return 'результат';
      case 2:
      case 3:
      case 4:
        return 'результата';
      default:
        return 'результатов';
    }
  }

  /// Shown when the hit cap in the JS `search()` was reached, so the list is
  /// only the first slice of what's in the book.
  static String searchCapped(int n) => t(
        tk: 'Ilkinji $n netije görkezilýär',
        ru: 'Показаны первые $n результатов',
        tr: 'İlk $n sonuç gösteriliyor',
        en: 'Showing the first $n results',
      );
}
