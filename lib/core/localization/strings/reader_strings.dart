import '../strings_base.dart';

/// Strings for the EPUB/PDF reader module: [ReaderScreen], [PdfReaderScreen],
/// [ReaderTabScreen], and the reader's bottom bar / settings sheet / chapter
/// list / selection toolbar widgets.
class ReaderStrings {
  ReaderStrings._();

  // ── PDF reader ────────────────────────────────────────────────────────
  static String pdfOpenError(String error) => t(
        tk: 'PDF açylmady: $error',
        ru: 'Не удалось открыть PDF: $error',
        tr: 'PDF açılamadı: $error',
      );

  // ── "Continue reading" tab empty state ──────────────────────────────────
  static String get noBookYetTitle => t(
        tk: 'Entäk okalýan kitap ýok',
        ru: 'Пока нет читаемой книги',
        tr: 'Henüz okunan kitap yok',
      );
  static String get noBookYetSubtitle => t(
        tk: 'Kitaphanaňyzdan bir kitap açyň,\nşu ýerden dowam etdirersiňiz.',
        ru: 'Откройте книгу из своей библиотеки,\nи продолжите чтение отсюда.',
        tr: 'Kütüphanenizden bir kitap açın,\nburadan devam edersiniz.',
      );

  // ── Reader screen ────────────────────────────────────────────────────
  static String get bookOpening => t(tk: 'Kitap açylýar...', ru: 'Книга открывается...', tr: 'Kitap açılıyor...');
  static String get copiedMessage => t(tk: 'Kopyalandy', ru: 'Скопировано', tr: 'Kopyalandı');

  // ── Bottom toolbar labels (TZ §12.3) ─────────────────────────────────
  static String get contentsLabel => t(tk: 'Mazmun', ru: 'Содержание', tr: 'İçindekiler');
  static String get searchShortLabel => t(tk: 'Gözleg', ru: 'Поиск', tr: 'Arama');

  // ── Chapter list sheet ───────────────────────────────────────────────
  static String get chaptersTitle => t(tk: 'Bölümler', ru: 'Главы', tr: 'Bölümler');
  static String get noChaptersFound => t(tk: 'Bölüm tapylmady', ru: 'Главы не найдены', tr: 'Bölüm bulunamadı');

  // ── Reader settings sheet ────────────────────────────────────────────
  static String get settingsTitle => t(tk: 'Sazlamalar', ru: 'Настройки', tr: 'Ayarlar');
  static String get backgroundColorLabel => t(tk: 'Fon reňki', ru: 'Цвет фона', tr: 'Arka plan rengi');
  static String get fontSizeLabel => t(tk: 'Şrift ölçegi', ru: 'Размер шрифта', tr: 'Yazı boyutu');
  static String get fontLabel => t(tk: 'Şrift', ru: 'Шрифт', tr: 'Yazı tipi');
  static String get lineSpacingLabel => t(tk: 'Setir aralygy', ru: 'Межстрочный интервал', tr: 'Satır aralığı');

  static String get themeWhite => t(tk: 'Ak', ru: 'Белый', tr: 'Beyaz');
  static String get themeSepia => t(tk: 'Sary', ru: 'Сепия', tr: 'Sarı');
  static String get themeDark => t(tk: 'Goňur', ru: 'Тёмный', tr: 'Koyu');
  static String get themeBlack => t(tk: 'Gara', ru: 'Чёрный', tr: 'Siyah');

  static String get brightnessLabel => t(tk: 'Parlaklyk', ru: 'Яркость', tr: 'Parlaklık');

  // ── Page transition sheet (TZ §12.2) ─────────────────────────────────
  static String get pageTransitionTitle => t(tk: 'Sahypa çalyşmak', ru: 'Смена страниц', tr: 'Sayfa geçişi');
  static String get transitionSlide => t(tk: 'Süýşürme', ru: 'Листание', tr: 'Kaydırma');
  static String get transitionCurl => t(tk: 'Sypyrmak', ru: 'Снятие', tr: 'Soyma');
  static String get transitionOverlay => t(tk: 'Üst gelmek', ru: 'Наложение', tr: 'Üste gelme');
  static String get transitionScroll => t(tk: 'Prokrutka', ru: 'Прокрутка', tr: 'Kaydırma (scroll)');
  static String get transitionShift => t(tk: 'Geçiş', ru: 'Сдвиг', tr: 'Öteleme');
  static String get transitionNone => t(tk: 'Animasiýasyz', ru: 'Без анимации', tr: 'Animasyonsuz');
  static String get leftHandLabel => t(tk: 'Çep el bilen', ru: 'Листать левой рукой', tr: 'Sol elle çevir');

  // ── In-book search (TZ §12.3) ────────────────────────────────────────
  static String get searchTitle => t(tk: 'Kitapdan gözle', ru: 'Поиск в книге', tr: 'Kitapta ara');
  static String get searchHint => t(tk: 'Söz ýa-da jümle...', ru: 'Слово или фраза...', tr: 'Kelime veya cümle...');
  static String get searchNoResults => t(tk: 'Netije tapylmady', ru: 'Ничего не найдено', tr: 'Sonuç bulunamadı');
  static String get searchPrompt => t(tk: 'Gözlemek üçin ýazyň', ru: 'Введите запрос для поиска', tr: 'Aramak için yazın');

  // ── Bookmark (TZ §12.1) ──────────────────────────────────────────────
  static String get bookmarkAdded => t(tk: 'Bellik goşuldy', ru: 'Закладка добавлена', tr: 'Yer imi eklendi');
  static String get bookmarkRemoved => t(tk: 'Bellik aýryldy', ru: 'Закладка удалена', tr: 'Yer imi kaldırıldı');
  static String get bookmarksTitle => t(tk: 'Bellikler', ru: 'Закладки', tr: 'Yer imleri');
  static String get bookmarksEmpty => t(
        tk: 'Bu kitapda entäk bellik ýok',
        ru: 'В этой книге пока нет закладок',
        tr: 'Bu kitapta henüz yer imi yok',
      );
  static String get addCurrentPage => t(tk: 'Şu sahypany belle', ru: 'Добавить эту страницу', tr: 'Bu sayfayı işaretle');
  static String get removeCurrentPage => t(tk: 'Şu sahypanyň belligini aýyr', ru: 'Убрать закладку с этой страницы', tr: 'Bu sayfanın yer imini kaldır');
  static String bookmarkProgress(int percent) => t(tk: '$percent% okaldy', ru: 'Прочитано $percent%', tr: '%$percent okundu');
  static String pageOfPages(int page, int total) =>
      t(tk: 'Sahypa $page / $total', ru: 'Страница $page из $total', tr: 'Sayfa $page / $total');

  // ── Selection toolbar (TZ §12.7) ─────────────────────────────────────
  static String get copyLabel => t(tk: 'Kopyala', ru: 'Копировать', tr: 'Kopyala');
  static String get highlightLabel => t(tk: 'Belle', ru: 'Выделить', tr: 'İşaretle');
  static String get noteLabel => t(tk: 'Not', ru: 'Заметка', tr: 'Not');
  static String get shareLabel => t(tk: 'Paýlaş', ru: 'Поделиться', tr: 'Paylaş');
  static String get highlightedMessage => t(tk: 'Bellendi', ru: 'Выделено', tr: 'İşaretlendi');
  static String get noteSavedMessage => t(tk: 'Not goşuldy', ru: 'Заметка добавлена', tr: 'Not eklendi');

  // ── Add-note sheet (TZ §12.7) ────────────────────────────────────────
  static String get addNoteTitle => t(tk: 'Not goş', ru: 'Добавить заметку', tr: 'Not ekle');
  static String get addNoteSubtitle => t(
        tk: 'Saýlanan tekst üçin bellik ýazyň',
        ru: 'Напишите заметку к выделенному тексту',
        tr: 'Seçili metin için not yazın',
      );
}
