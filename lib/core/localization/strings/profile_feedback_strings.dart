import '../strings_base.dart';

/// Strings for the profile module's two feedback sheets — [BookRequestSheet]
/// and [ReportProblemSheet] — which share the same "Iber" send button.
/// [ProfileStrings.reportProblemEntryTitle] additionally appears as
/// [ProfileScreen]'s menu row label for opening the problem sheet. Split out
/// of [ProfileStrings] to keep that file under the 200-line limit.
class ProfileFeedbackStrings {
  ProfileFeedbackStrings._();

  // ── book_request_sheet.dart ─────────────────────────────────────────────
  static String get languageTurkmen =>
      t(tk: 'Türkmen dili', ru: 'Туркменский язык', tr: 'Türkmence');
  static String get languageTurkish =>
      t(tk: 'Türk dili', ru: 'Турецкий язык', tr: 'Türkçe');
  static String get languageRussian =>
      t(tk: 'Rus dili', ru: 'Русский язык', tr: 'Rusça');
  static String get languageEnglish =>
      t(tk: 'Iňlis dili', ru: 'Английский язык', tr: 'İngilizce');
  static String get languageOther =>
      t(tk: 'Beýleki', ru: 'Другое', tr: 'Diğer');
  static String get bookRequestSentSuccess => t(
        tk: 'Haýyşyňyz iberildi',
        ru: 'Ваш запрос отправлен',
        tr: 'İsteğiniz gönderildi',
      );
  static String get bookRequestTitle =>
      t(tk: 'Kitap haýyşy', ru: 'Запрос книги', tr: 'Kitap talebi');
  static String get bookRequestSubtitle => t(
        tk: 'Programmada ýok kitaby haýyş ediň',
        ru: 'Запросите книгу, которой нет в приложении',
        tr: 'Uygulamada olmayan bir kitabı talep edin',
      );
  static String get bookTitleLabel =>
      t(tk: 'Kitap ady', ru: 'Название книги', tr: 'Kitap adı');
  static String get bookTitleHint => t(
        tk: 'Mysal: Ýitgi we tapyş',
        ru: 'Например: Потеря и находка',
        tr: 'Örnek: Kayıp ve Buluş',
      );
  static String get authorNameLabel =>
      t(tk: 'Ýazar ady', ru: 'Имя автора', tr: 'Yazar adı');
  static String get authorNameHint => t(
        tk: 'Mysal: Osman Ödäýew',
        ru: 'Например: Осман Одаев',
        tr: 'Örnek: Osman Ödeýew',
      );
  static String get descriptionLabel => t(
        tk: 'Beýany (hökman däl)',
        ru: 'Описание (необязательно)',
        tr: 'Açıklama (opsiyonel)',
      );
  static String get descriptionHint => t(
        tk: 'Kitap barada goşmaça maglumat',
        ru: 'Дополнительная информация о книге',
        tr: 'Kitap hakkında ek bilgi',
      );
  static String get languageLabel => t(tk: 'Dili', ru: 'Язык', tr: 'Dili');
  static String get send => t(tk: 'Iber', ru: 'Отправить', tr: 'Gönder');

  // ── report_problem_sheet.dart ───────────────────────────────────────────
  static String get reportProblemTitle => t(
        tk: 'Ýalnyşlyk barada habar ber',
        ru: 'Сообщить о проблеме',
        tr: 'Sorun bildir',
      );
  static String get reportProblemSubtitle => t(
        tk: 'Duşan kynçylygyňyzy beýan ediň, biz derňäris',
        ru: 'Опишите проблему, с которой столкнулись — мы разберёмся',
        tr: 'Karşılaştığınız sorunu anlatın, inceleyelim',
      );
  static String get reportProblemHint => t(
        tk: 'Näme boldy? Mümkin boldugyça jikme-jik ýazyň...',
        ru: 'Что произошло? Опишите как можно подробнее...',
        tr: 'Ne oldu? Mümkün olduğunca ayrıntılı yazın...',
      );
  static String get reportProblemSentSuccess => t(
        tk: 'Habaryňyz iberildi, sag boluň!',
        ru: 'Ваше сообщение отправлено, спасибо!',
        tr: 'Bildiriminiz gönderildi, teşekkürler!',
      );
  static String get reportProblemEntryTitle => t(
        tk: 'Ýalnyşlyk barada habar ber',
        ru: 'Сообщить о проблеме',
        tr: 'Sorun bildir',
      );
  static String get reportProblemTooShort => t(
        tk: 'Azyndan 10 harp ýazyň',
        ru: 'Введите не менее 10 символов',
        tr: 'En az 10 karakter yazın',
      );
}
