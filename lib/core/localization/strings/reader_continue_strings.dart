import '../strings_base.dart';

/// Strings for the "continue reading" empty/filled states — [ContinueReadingCard]
/// and [ReaderEmptyState]. Split out of [ReaderStrings] to keep that file
/// under the 200-line limit; both call sites use only this section, so
/// their import swaps over cleanly.
class ReaderContinueStrings {
  ReaderContinueStrings._();

  static String get noBookYetTitle => t(
        tk: 'Entäk okalýan kitap ýok',
        ru: 'Пока нет читаемой книги',
        tr: 'Henüz okunan kitap yok',
        en: 'No book being read yet',
      );
  static String get noBookYetSubtitle => t(
        tk: 'Kitaphanaňyzdan bir kitap açyň,\nşu ýerden dowam etdirersiňiz.',
        ru: 'Откройте книгу из своей библиотеки,\nи продолжите чтение отсюда.',
        tr: 'Kütüphanenizden bir kitap açın,\nburadan devam edersiniz.',
        en: 'Open a book from your library,\nand you\'ll continue it from here.',
      );
  static String get continueReading => t(
        tk: 'Okamagy dowam et',
        ru: 'Продолжить чтение',
        tr: 'Okumaya devam et',
        en: 'Continue reading',
      );
  static String resumeAtPage(int page) => t(
        tk: '$page-nji sahypadan dowam et',
        ru: 'Продолжить со стр. $page',
        tr: '$page. sayfadan devam et',
        en: 'Resume at page $page',
      );
  static String resumeAtPageOf(int page, int total) => t(
        tk: '$page / $total sahypa',
        ru: '$page / $total стр.',
        tr: '$page / $total. sayfa',
        en: '$page / $total pages',
      );
}
