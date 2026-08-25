import '../strings_base.dart';

/// The PDF reader's own strings — [PdfReaderScreen], its settings sheet and
/// the "go to page" sheet. Split out of [ReaderStrings], which had grown past
/// the project's 200-line file limit; the EPUB/CBZ reader strings and the
/// shared appearance labels (brightness, eye care, colour mode) stay there.
class ReaderPdfStrings {
  ReaderPdfStrings._();

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

  /// Trims the blank print margin down each side of the page so the text
  /// block fills the screen — see [PdfMarginCropBox].
  static String get pdfMarginCropLabel => t(
      tk: 'Gyra boşlugy',
      ru: 'Поля страницы',
      tr: 'Kenar boşluğu',
      en: 'Page margins');

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
}
