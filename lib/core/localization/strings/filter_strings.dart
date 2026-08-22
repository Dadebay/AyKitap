import '../strings_base.dart';

/// Strings for [FilterScreen].
class FilterStrings {
  FilterStrings._();

  static String get title => t(tk: 'Filtrler', ru: 'Фильтры', tr: 'Filtreler');
  static String get quickFilters =>
      t(tk: 'Çalt filtrler', ru: 'Быстрые фильтры', tr: 'Hızlı filtreler');
  static String get sorting =>
      t(tk: 'Tertiplemek', ru: 'Сортировка', tr: 'Sıralama');
  static String get language => t(tk: 'Dil', ru: 'Язык', tr: 'Dil');
  static String get genre => t(tk: 'Žanr', ru: 'Жанр', tr: 'Tür');
  static String get format => t(tk: 'Format', ru: 'Формат', tr: 'Format');
  static String get publishDate =>
      t(tk: 'Çap senesi', ru: 'Дата публикации', tr: 'Yayın tarihi');
  static String get any => t(tk: 'Islendik', ru: 'Любой', tr: 'Herhangi biri');
  static String get sortOrder => t(
      tk: 'Bellenen tertip boýunça',
      ru: 'По заданному порядку',
      tr: 'Belirlenen sıraya göre');
  static String get clearFilter =>
      t(tk: 'Filtri arassala', ru: 'Очистить фильтр', tr: 'Filtreyi temizle');
  static String get showResults => t(
      tk: 'Netijeleri görkez',
      ru: 'Показать результаты',
      tr: 'Sonuçları göster');

  // Language section (the book's language — distinct from the app's own UI
  // language picker in Settings). The options themselves come from
  // `GET /book-languages`, already translated, so only these two are local.
  static String get langLoadFailed => t(
      tk: 'Diller ýüklenmedi',
      ru: 'Не удалось загрузить языки',
      tr: 'Diller yüklenemedi');
  static String get retry =>
      t(tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene');

  // Genre section — options come from `GET /genres/all`, already translated,
  // so only the failure copy is local.
  static String get genreLoadFailed => t(
      tk: 'Žanrlar ýüklenmedi',
      ru: 'Не удалось загрузить жанры',
      tr: 'Türler yüklenemedi');

  // File format filter options — technical/format labels, same across
  // languages. Only the three `GET /books/all?book_format=` accepts; MOBI
  // was dropped because no backend filter can serve it.
  static String get formatEpub => t(tk: 'EPUB', ru: 'EPUB', tr: 'EPUB');
  static String get formatPdf => t(tk: 'PDF', ru: 'PDF', tr: 'PDF');
  static String get formatCbzManga =>
      t(tk: 'CBZ (Manga)', ru: 'CBZ (Манга)', tr: 'CBZ (Manga)');

  // Sort-by option labels.
  static String get sortByName => t(tk: '(A→Z)', ru: '(A→Z)', tr: '(A→Z)');
  static String get sortByPublishNewOld => t(
      tk: 'Çap senesi (täzeden köne)',
      ru: 'Дата публикации (сначала новые)',
      tr: 'Yayın tarihi (yeniden eskiye)');
  static String get sortByPublishOldNew => t(
      tk: 'Çap senesi (köneden täze)',
      ru: 'Дата публикации (сначала старые)',
      tr: 'Yayın tarihi (eskiden yeniye)');
  static String get sortByUploadNewOld => t(
      tk: 'Ýüklenen wagty (täzeden köne)',
      ru: 'Время загрузки (сначала новые)',
      tr: 'Yüklenme zamanı (yeniden eskiye)');
}
