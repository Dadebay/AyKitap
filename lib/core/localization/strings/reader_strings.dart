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

  // ── Chapter list sheet ───────────────────────────────────────────────
  static String get chaptersTitle => t(tk: 'Bölümler', ru: 'Главы', tr: 'Bölümler');
  static String get noChaptersFound => t(tk: 'Bölüm tapylmady', ru: 'Главы не найдены', tr: 'Bölüm bulunamadı');

  // ── Reader settings sheet ────────────────────────────────────────────
  static String get backgroundColorLabel => t(tk: 'Fon reňki', ru: 'Цвет фона', tr: 'Arka plan rengi');
  static String get fontSizeLabel => t(tk: 'Şrift ölçegi', ru: 'Размер шрифта', tr: 'Yazı boyutu');
  static String get fontLabel => t(tk: 'Şrift', ru: 'Шрифт', tr: 'Yazı tipi');
  static String get lineSpacingLabel => t(tk: 'Setir aralygy', ru: 'Межстрочный интервал', tr: 'Satır aralığı');

  static String get themeWhite => t(tk: 'Ak', ru: 'Белый', tr: 'Beyaz');
  static String get themeSepia => t(tk: 'Sary', ru: 'Сепия', tr: 'Sarı');
  static String get themeDark => t(tk: 'Goňur', ru: 'Тёмный', tr: 'Koyu');
  static String get themeBlack => t(tk: 'Gara', ru: 'Чёрный', tr: 'Siyah');

  // ── Selection toolbar ────────────────────────────────────────────────
  static String get copyLabel => t(tk: 'Kopyala', ru: 'Копировать', tr: 'Kopyala');
}
