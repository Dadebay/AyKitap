import '../strings_base.dart';

/// Strings for the EPUB/PDF reader module: [ReaderScreen], [PdfReaderScreen],
/// [ReaderTabScreen], and the reader's bottom bar / settings sheet / chapter
/// list / selection toolbar widgets.
class ReaderStrings {
  ReaderStrings._();

  // ── CBZ reader (comic/manga chapter, a zip of page images) ──────────────
  static String cbzOpenError(String error) => t(
        tk: 'CBZ açylmady: $error',
        ru: 'Не удалось открыть CBZ: $error',
        tr: 'CBZ açılamadı: $error',
        en: 'The CBZ couldn\'t open: $error',
      );
  static String get cbzNoImagesError => t(
        tk: 'Bu faýlda sahypa resimi tapylmady',
        ru: 'В этом файле не найдено страниц-изображений',
        tr: 'Bu dosyada sayfa resmi bulunamadı',
        en: 'No page images were found in this file',
      );
  static String get cbzExtracting => t(
      tk: 'Sahypalar taýýarlanýar...',
      ru: 'Подготовка страниц...',
      tr: 'Sayfalar hazırlanıyor...',
      en: 'Preparing pages...');
  static String get cbzFitContain =>
      t(tk: 'Doly sahypa', ru: 'Вся страница', tr: 'Tam sayfa', en: 'Fit page');
  static String get cbzFitCover => t(
      tk: 'Ekrany doldur',
      ru: 'Заполнить экран',
      tr: 'Ekranı doldur',
      en: 'Fill screen');

  // ── "Continue reading" tab empty state ──────────────────────────────────
  // Moved to ReaderContinueStrings — see that file.

  // ── Reader screen ────────────────────────────────────────────────────
  static String get bookOpening => t(
      tk: 'Kitap açylýar...',
      ru: 'Книга открывается...',
      tr: 'Kitap açılıyor...',
      en: 'Opening the book...');
  static String get copiedMessage =>
      t(tk: 'Kopyalandy', ru: 'Скопировано', tr: 'Kopyalandı', en: 'Copied');
  static String get epubOpenError => t(
        tk: 'Bu kitap açylmady. Faýl zaýalanan ýa-da goldanylmaýan bolmagy mümkin.',
        ru: 'Не удалось открыть эту книгу. Файл может быть повреждён или не поддерживается.',
        tr: 'Bu kitap açılamadı. Dosya bozuk veya desteklenmiyor olabilir.',
        en: 'This book couldn\'t open. The file may be corrupted or unsupported.',
      );

  // ── Bottom toolbar labels (TZ §12.3) ─────────────────────────────────
  static String get contentsLabel =>
      t(tk: 'Mazmun', ru: 'Содержание', tr: 'İçindekiler', en: 'Contents');
  static String get searchShortLabel =>
      t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama', en: 'Search');

  // ── Chapter list sheet ───────────────────────────────────────────────
  static String get chaptersTitle =>
      t(tk: 'Bölümler', ru: 'Главы', tr: 'Bölümler', en: 'Chapters');
  static String get noChaptersFound => t(
      tk: 'Bölüm tapylmady',
      ru: 'Главы не найдены',
      tr: 'Bölüm bulunamadı',
      en: 'No chapters found');

  // ── Reader settings sheet ────────────────────────────────────────────
  static String get settingsTitle =>
      t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar', en: 'Settings');
  static String get backgroundColorLabel => t(
      tk: 'Fon reňki',
      ru: 'Цвет фона',
      tr: 'Arka plan rengi',
      en: 'Background color');
  static String get pdfColorModeLabel => t(
      tk: 'Reňk tertibi', ru: 'Режим цвета', tr: 'Renk modu', en: 'Color mode');
  static String get themeNight =>
      t(tk: 'Gije', ru: 'Ночь', tr: 'Gece', en: 'Night');
  static String get fontSizeLabel => t(
      tk: 'Şrift ölçegi',
      ru: 'Размер шрифта',
      tr: 'Yazı boyutu',
      en: 'Font size');
  static String get fontLabel =>
      t(tk: 'Şrift', ru: 'Шрифт', tr: 'Yazı tipi', en: 'Font');
  static String get lineSpacingLabel => t(
      tk: 'Setir aralygy',
      ru: 'Межстрочный интервал',
      tr: 'Satır aralığı',
      en: 'Line spacing');

  static String get themeWhite =>
      t(tk: 'Ak', ru: 'Белый', tr: 'Beyaz', en: 'White');
  static String get themeSepia =>
      t(tk: 'Sary', ru: 'Сепия', tr: 'Sarı', en: 'Sepia');
  static String get themeDark =>
      t(tk: 'Goňur', ru: 'Тёмный', tr: 'Koyu', en: 'Dark');
  static String get themeBlack =>
      t(tk: 'Gara', ru: 'Чёрный', tr: 'Siyah', en: 'Black');

  static String get brightnessLabel =>
      t(tk: 'Parlaklyk', ru: 'Яркость', tr: 'Parlaklık', en: 'Brightness');

  /// Blue-light filter that warms the page to reduce eye strain (TZ §12.4).
  static String get eyeCareLabel => t(
      tk: 'Göz goraýyş',
      ru: 'Защита глаз',
      tr: 'Göz koruması',
      en: 'Eye comfort');

  // ── Page transition sheet (TZ §12.2) ─────────────────────────────────
  static String get pageTransitionTitle => t(
      tk: 'Sahypa çalyşmak',
      ru: 'Смена страниц',
      tr: 'Sayfa geçişi',
      en: 'Page transition');
  static String get transitionSlide =>
      t(tk: 'Süýşürme', ru: 'Листание', tr: 'Kaydırma', en: 'Slide');
  static String get transitionCurl =>
      t(tk: 'Sypyrmak', ru: 'Снятие', tr: 'Soyma', en: 'Curl');
  static String get transitionOverlay =>
      t(tk: 'Üst gelmek', ru: 'Наложение', tr: 'Üste gelme', en: 'Overlay');
  static String get transitionScroll => t(
      tk: 'Prokrutka', ru: 'Прокрутка', tr: 'Kaydırma (scroll)', en: 'Scroll');
  static String get transitionShift =>
      t(tk: 'Geçiş', ru: 'Сдвиг', tr: 'Öteleme', en: 'Shift');
  static String get transitionNone => t(
      tk: 'Animasiýasyz',
      ru: 'Без анимации',
      tr: 'Animasyonsuz',
      en: 'No animation');
  static String get leftHandLabel => t(
      tk: 'Çep el bilen',
      ru: 'Листать левой рукой',
      tr: 'Sol elle çevir',
      en: 'Left-handed');

  // ── In-book search (TZ §12.3) ────────────────────────────────────────
  // Moved to ReaderSearchStrings — see that file.

  /// Badge on the chapter list's current row.
  static String get currentlyReadingBadge =>
      t(tk: 'Okalýar', ru: 'Читаю', tr: 'Okunuyor', en: 'Reading');

  // ── Bookmark (TZ §12.1) ──────────────────────────────────────────────
  // Moved to ReaderBookmarkStrings — see that file.

  // ── Selection toolbar (TZ §12.7) / Add-note sheet ────────────────────
  // Moved to ReaderNotesStrings — see that file.
}
