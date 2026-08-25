import '../strings_base.dart';

/// Strings for the EPUB/PDF reader module: [ReaderScreen], [PdfReaderScreen],
/// [ReaderTabScreen], and the reader's bottom bar / settings sheet / chapter
/// list / selection toolbar widgets.
class ReaderStrings {
  ReaderStrings._();

  // ── PDF reader ────────────────────────────────────────────────────────
  /// Deliberately generic — the raw platform exception is developer noise
  /// (often a bare "PlatformException(...)"), not something to show a
  /// reader. See PdfReaderScreen.onError, which logs the real error instead.
  static String get pdfOpenError => t(
        tk: 'PDF açylmady. Faýl zaýalanan ýa-da parolly bolmagy mümkin.',
        ru: 'Не удалось открыть PDF. Файл может быть повреждён или защищён паролем.',
        tr: 'PDF açılamadı. Dosya bozuk veya şifreli olabilir.',
        en: 'The PDF couldn\'t open. The file may be corrupted or password-protected.',
      );

  /// Bottom-bar button label — short on purpose, it sits under a 22px icon.
  static String get pdfGoToPageShort =>
      t(tk: 'Sahypa', ru: 'Страница', tr: 'Sayfa', en: 'Page');
  static String get pdfGoToPageTitle => t(
      tk: 'Sahypa geç',
      ru: 'Перейти к странице',
      tr: 'Sayfaya git',
      en: 'Go to page');
  static String get pdfGoToPageAction =>
      t(tk: 'Geç', ru: 'Перейти', tr: 'Git', en: 'Go');
  static String pdfGoToPageHint(int total) => t(
        tk: '1 – $total aralygynda',
        ru: 'От 1 до $total',
        tr: '1 – $total arasında',
        en: 'Between 1 and $total',
      );

  /// How a page is scaled to the screen — the PDF counterpart of the EPUB
  /// reader's layout settings.
  static String get pdfFitLabel => t(
      tk: 'Sahypa ölçegi',
      ru: 'Масштаб страницы',
      tr: 'Sayfa ölçeği',
      en: 'Page scale');
  static String get pdfFitWidth => t(
      tk: 'Ini boýunça',
      ru: 'По ширине',
      tr: 'Genişliğe göre',
      en: 'Fit width');
  static String get pdfFitPage =>
      t(tk: 'Doly sahypa', ru: 'Вся страница', tr: 'Tam sayfa', en: 'Fit page');

  /// Whether pages turn sideways one at a time, or scroll continuously top
  /// to bottom — the latter is what makes very tall pages (webtoon/manhwa
  /// strips) readable instead of shrinking them to fit the screen height.
  static String get pdfViewModeLabel => t(
      tk: 'Okaýyş görnüşi',
      ru: 'Режим просмотра',
      tr: 'Görünüm modu',
      en: 'Viewing mode');
  static String get pdfViewModePaged =>
      t(tk: 'Sahypalap', ru: 'Постранично', tr: 'Sayfa sayfa', en: 'Paged');
  static String get pdfViewModeScroll =>
      t(tk: 'Dowamly aýlaw', ru: 'Прокруткой', tr: 'Kaydırmalı', en: 'Scroll');

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

  /// Switches a PDF opened in the reflowed (text) reader back to the
  /// original fixed page images — an escape hatch for books whose source
  /// PDF has a broken font/text-encoding that turns some sentences into
  /// gibberish once extracted, even though the page itself renders fine.
  static String get pdfOriginalViewLabel => t(
        tk: 'Asyl PDF sahypalary',
        ru: 'Исходные страницы PDF',
        tr: 'Orijinal PDF sayfaları',
        en: 'Original PDF pages',
      );
  static String get pdfOriginalViewHint => t(
        tk: 'Sözler üýtgeýän bolsa, sahypanyň resimini görkez',
        ru: 'Если слова искажены, показать страницу как изображение',
        tr: 'Kelimeler bozuk görünüyorsa sayfayı resim olarak göster',
        en: 'If the words look wrong, show the page as an image instead',
      );

  /// Reverse of the above, offered from the fixed-page PDF reader — which is
  /// where every PDF now opens by default.
  static String get pdfTextViewLabel => t(
      tk: 'Tekst görnüşi',
      ru: 'Текстовый вид',
      tr: 'Metin görünümü',
      en: 'Text view');
  static String get pdfTextViewHint => t(
        tk: 'Ýazgyny üýtgedip, ýerleşdirip okamak',
        ru: 'Читать с переносом текста и настройками шрифта',
        tr: 'Yeniden akan, yazı tipi ayarlanabilir görünüme dön',
        en: 'Switch to a reflowable view with adjustable font',
      );

  /// Shown when that conversion turns out to be impossible — a scanned or
  /// image-only PDF has no text layer to reflow.
  static String get pdfTextViewUnavailable => t(
        tk: 'Bu kitapda tekst ýok — diňe sahypa suratlary',
        ru: 'В этой книге нет текстового слоя — только изображения страниц',
        tr: 'Bu kitapta metin katmanı yok — yalnızca sayfa görüntüleri',
        en: 'This book has no text layer — only page images',
      );

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
