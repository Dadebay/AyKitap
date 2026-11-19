import '../strings_base.dart';

class NextBookStrings {
  NextBookStrings._();

  static String get title => t(
      tk: 'Indiki kitabyň',
      ru: 'Ваша следующая книга',
      tr: 'Sıradaki kitabın',
      en: 'Your next book');
  static String get open => t(
      tk: 'Kitaby gör', ru: 'Открыть книгу', tr: 'Kitabı gör', en: 'View book');
  static String get finished => t(
      tk: 'Kitaby tamamladyňyz!',
      ru: 'Вы закончили книгу!',
      tr: 'Kitabı bitirdin!',
      en: 'You finished the book!');
}
