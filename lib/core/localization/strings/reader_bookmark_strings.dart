import '../strings_base.dart';

/// Strings for bookmarks (TZ §12.1) — [BookmarksSheet], [PdfBookmarksSheet],
/// [ChapterListSheet]'s current-position row, and the bookmark toggle
/// snackbars in the epub/PDF/CBZ readers. Split out of [ReaderStrings] to
/// keep that file under the 200-line limit.
class ReaderBookmarkStrings {
  ReaderBookmarkStrings._();

  static String get bookmarkAdded =>
      t(tk: 'Bellik goşuldy', ru: 'Закладка добавлена', tr: 'Yer imi eklendi');
  static String get bookmarkRemoved =>
      t(tk: 'Bellik aýryldy', ru: 'Закладка удалена', tr: 'Yer imi kaldırıldı');
  static String get bookmarksTitle =>
      t(tk: 'Bellikler', ru: 'Закладки', tr: 'Yer imleri');
  static String get bookmarksEmpty => t(
        tk: 'Bu kitapda entäk bellik ýok',
        ru: 'В этой книге пока нет закладок',
        tr: 'Bu kitapta henüz yer imi yok',
      );
  static String get addCurrentPage => t(
      tk: 'Şu sahypany belle',
      ru: 'Добавить эту страницу',
      tr: 'Bu sayfayı işaretle');
  static String get removeCurrentPage => t(
      tk: 'Şu sahypanyň belligini aýyr',
      ru: 'Убрать закладку с этой страницы',
      tr: 'Bu sayfanın yer imini kaldır');
  static String bookmarkProgress(int percent) => t(
      tk: '$percent% okaldy',
      ru: 'Прочитано $percent%',
      tr: '%$percent okundu');
  static String pageOfPages(int page, int total) => t(
      tk: 'Sahypa $page / $total',
      ru: 'Страница $page из $total',
      tr: 'Sayfa $page / $total');
}
