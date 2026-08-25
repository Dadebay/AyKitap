import '../strings_base.dart';

/// Strings for [FilterScreen].
class FilterStrings {
  FilterStrings._();

  static String get title =>
      t(tk: 'Filtrler', ru: 'Фильтры', tr: 'Filtreler', en: 'Filters');
  static String get quickFilters => t(
      tk: 'Çalt filtrler',
      ru: 'Быстрые фильтры',
      tr: 'Hızlı filtreler',
      en: 'Quick filters');
  static String get sorting =>
      t(tk: 'Tertiplemek', ru: 'Сортировка', tr: 'Sıralama', en: 'Sorting');
  static String get language =>
      t(tk: 'Dil', ru: 'Язык', tr: 'Dil', en: 'Language');
  static String get genre => t(tk: 'Žanr', ru: 'Жанр', tr: 'Tür', en: 'Genre');
  static String get format =>
      t(tk: 'Format', ru: 'Формат', tr: 'Format', en: 'Format');
  static String get publishDate => t(
      tk: 'Çap senesi',
      ru: 'Дата публикации',
      tr: 'Yayın tarihi',
      en: 'Publish year');
  static String get any =>
      t(tk: 'Islendik', ru: 'Любой', tr: 'Herhangi biri', en: 'Any');
  static String get sortOrder => t(
      tk: 'Bellenen tertip boýunça',
      ru: 'По заданному порядку',
      tr: 'Belirlenen sıraya göre',
      en: 'By the selected order');
  static String get clearFilter => t(
      tk: 'Filtri arassala',
      ru: 'Очистить фильтр',
      tr: 'Filtreyi temizle',
      en: 'Clear filter');
  static String get showResults => t(
      tk: 'Netijeleri görkez',
      ru: 'Показать результаты',
      tr: 'Sonuçları göster',
      en: 'Show results');

  // Language section (the book's language — distinct from the app's own UI
  // language picker in Settings). The options themselves come from
  // `GET /book-languages`, already translated, so only these two are local.
  static String get langLoadFailed => t(
      tk: 'Diller ýüklenmedi',
      ru: 'Не удалось загрузить языки',
      tr: 'Diller yüklenemedi',
      en: 'Languages couldn\'t load');
  static String get retry => t(
      tk: 'Gaýtadan synanyş', ru: 'Повторить', tr: 'Tekrar dene', en: 'Retry');

  // Genre section — options come from `GET /genres/all`, already translated,
  // so only the failure copy is local.
  static String get genreLoadFailed => t(
      tk: 'Žanrlar ýüklenmedi',
      ru: 'Не удалось загрузить жанры',
      tr: 'Türler yüklenemedi',
      en: 'Genres couldn\'t load');

  // File format filter options — technical/format labels, same across
  // languages. Only the three `GET /books/all?book_format=` accepts; MOBI
  // was dropped because no backend filter can serve it.
  static String get formatEpub =>
      t(tk: 'EPUB', ru: 'EPUB', tr: 'EPUB', en: 'EPUB');
  static String get formatPdf => t(tk: 'PDF', ru: 'PDF', tr: 'PDF', en: 'PDF');
  static String get formatCbzManga => t(
      tk: 'CBZ (Manga)',
      ru: 'CBZ (Манга)',
      tr: 'CBZ (Manga)',
      en: 'CBZ (Manga)');

  // Sort-by option labels.
  static String get sortByName =>
      t(tk: '(A→Z)', ru: '(A→Z)', tr: '(A→Z)', en: '(A→Z)');
  static String get sortByPublishNewOld => t(
      tk: 'Çap senesi (täzeden köne)',
      ru: 'Дата публикации (сначала новые)',
      tr: 'Yayın tarihi (yeniden eskiye)',
      en: 'Publish year (newest first)');
  static String get sortByPublishOldNew => t(
      tk: 'Çap senesi (köneden täze)',
      ru: 'Дата публикации (сначала старые)',
      tr: 'Yayın tarihi (eskiden yeniye)',
      en: 'Publish year (oldest first)');
  static String get sortByUploadNewOld => t(
      tk: 'Ýüklenen wagty (täzeden köne)',
      ru: 'Время загрузки (сначала новые)',
      tr: 'Yüklenme zamanı (yeniden eskiye)',
      en: 'Upload time (newest first)');
}
