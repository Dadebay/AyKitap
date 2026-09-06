import '../strings_base.dart';

/// Strings for the profile module's two feedback sheets — [BookRequestSheet]
/// and [ReportProblemSheet] — which share the same "Iber" send button.
/// [ProfileStrings.reportProblemEntryTitle] additionally appears as
/// [ProfileScreen]'s menu row label for opening the problem sheet. Split out
/// of [ProfileStrings] to keep that file under the 200-line limit.
class ProfileFeedbackStrings {
  ProfileFeedbackStrings._();

  // ── book_request_sheet.dart ─────────────────────────────────────────────
  static String get languageTurkmen => t(tk: 'Türkmen dili', ru: 'Туркменский язык', tr: 'Türkmence', en: 'Turkmen');
  static String get languageTurkish => t(tk: 'Türk dili', ru: 'Турецкий язык', tr: 'Türkçe', en: 'Turkish');
  static String get languageRussian => t(tk: 'Rus dili', ru: 'Русский язык', tr: 'Rusça', en: 'Russian');
  static String get languageEnglish => t(tk: 'Iňlis dili', ru: 'Английский язык', tr: 'İngilizce', en: 'English');
  static String get languageOther => t(tk: 'Beýleki', ru: 'Другое', tr: 'Diğer', en: 'Other');
  static String get bookRequestSentSuccess => t(
        tk: 'Haýyşyňyz iberildi',
        ru: 'Ваш запрос отправлен',
        tr: 'İsteğiniz gönderildi',
        en: 'Your request was sent',
      );
  static String get bookRequestTitle => t(tk: 'Kitap haýyşy', ru: 'Запрос книги', tr: 'Kitap talebi', en: 'Book request');
  static String get bookRequestSubtitle => t(
        tk: 'Programmada ýok kitaby haýyş ediň',
        ru: 'Запросите книгу, которой нет в приложении',
        tr: 'Uygulamada olmayan bir kitabı talep edin',
        en: 'Request a book that isn\'t in the app',
      );
  static String get bookTitleLabel => t(tk: 'Kitap ady', ru: 'Название книги', tr: 'Kitap adı', en: 'Book title');
  static String get bookTitleHint => t(
        tk: 'Mysal: Ýitgi we tapyş',
        ru: 'Например: Потеря и находка',
        tr: 'Örnek: Kayıp ve Buluş',
        en: 'E.g. Lost and Found',
      );
  static String get authorNameLabel => t(tk: 'Awtor ady', ru: 'Имя автора', tr: 'Yazar adı', en: 'Author name');
  static String get authorNameHint => t(
        tk: 'Mysal: Osman Ödäýew',
        ru: 'Например: Осман Одаев',
        tr: 'Örnek: Osman Ödeýew',
        en: 'E.g. Osman Odayev',
      );
  static String get descriptionLabel => t(
        tk: 'Beýany (hökman däl)',
        ru: 'Описание (необязательно)',
        tr: 'Açıklama (opsiyonel)',
        en: 'Description (optional)',
      );
  static String get descriptionHint => t(
        tk: 'Kitap barada goşmaça maglumat',
        ru: 'Дополнительная информация о книге',
        tr: 'Kitap hakkında ek bilgi',
        en: 'Extra info about the book',
      );
  static String get languageLabel => t(tk: 'Dili', ru: 'Язык', tr: 'Dili', en: 'Language');
  static String get send => t(tk: 'Iber', ru: 'Отправить', tr: 'Gönder', en: 'Send');

  // ── report_problem_sheet.dart ───────────────────────────────────────────
  static String get reportProblemTitle => t(
        tk: 'Ýalnyşlyk barada habar ber',
        ru: 'Сообщить о проблеме',
        tr: 'Sorun bildir',
        en: 'Report a problem',
      );
  static String get reportProblemSubtitle => t(
        tk: 'Duşan kynçylygyňyzy beýan ediň, biz derňäris',
        ru: 'Опишите проблему, с которой столкнулись — мы разберёмся',
        tr: 'Karşılaştığınız sorunu anlatın, inceleyelim',
        en: 'Describe the problem you ran into — we\'ll look into it',
      );
  static String get reportProblemHint => t(
        tk: 'Näme boldy? Mümkin boldugyça jikme-jik ýazyň...',
        ru: 'Что произошло? Опишите как можно подробнее...',
        tr: 'Ne oldu? Mümkün olduğunca ayrıntılı yazın...',
        en: 'What happened? Please describe it in as much detail as you can...',
      );
  static String get reportProblemSentSuccess => t(
        tk: 'Habaryňyz iberildi, sag boluň!',
        ru: 'Ваше сообщение отправлено, спасибо!',
        tr: 'Bildiriminiz gönderildi, teşekkürler!',
        en: 'Your report was sent, thank you!',
      );
  static String get reportProblemEntryTitle => t(
        tk: 'Ýalnyşlyk barada habar ber',
        ru: 'Сообщить о проблеме',
        tr: 'Sorun bildir',
        en: 'Report a problem',
      );
  static String get reportProblemTooShort => t(
        tk: 'Azyndan 10 harp ýazyň',
        ru: 'Введите не менее 10 символов',
        tr: 'En az 10 karakter yazın',
        en: 'Type at least 10 characters',
      );
}
