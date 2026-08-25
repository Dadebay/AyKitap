import '../strings_base.dart';

/// Strings for [LanguageSelectScreen] — the one-time language picker shown
/// right after onboarding, before the user's first real entry into the app.
class LanguageSelectStrings {
  LanguageSelectStrings._();

  static String get title => t(
      tk: 'Dili saýlaň',
      ru: 'Выберите язык',
      tr: 'Dili seçin',
      en: 'Choose a language');
  static String get subtitle => t(
        tk: 'Programmanyň dilini saýlaň. Muny islendik wagt Sazlamalardan üýtgedip bilersiňiz.',
        ru: 'Выберите язык приложения. Вы всегда сможете изменить его в настройках.',
        tr: 'Uygulamanın dilini seçin. Bunu istediğiniz zaman ayarlardan değiştirebilirsiniz.',
        en: 'Choose the app\'s language. You can always change it later in Settings.',
      );
  static String get continueLabel =>
      t(tk: 'Dowam et', ru: 'Продолжить', tr: 'Devam et', en: 'Continue');
}
