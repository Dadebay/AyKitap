import '../strings_base.dart';

/// Strings for [AuthorScreen] and [AllAuthorsScreen].
class AuthorStrings {
  AuthorStrings._();

  static String booksCountLabel(int count) => t(tk: '$count kitap', ru: '$count книг', tr: '$count kitap');
  static String get showLess => t(tk: 'Az görkez', ru: 'Свернуть', tr: 'Daha az göster');
  static String get readMore => t(tk: 'Dowamyny oka', ru: 'Читать далее', tr: 'Devamını oku');
  static String get allBooks => t(tk: 'Ähli kitaplary', ru: 'Все книги', tr: 'Tüm kitapları');
  static String pagesLabel(int count) => t(tk: '$count sahypa', ru: '$count страниц', tr: '$count sayfa');
  static String get authorsTitle => t(tk: 'Ýazarlar', ru: 'Авторы', tr: 'Yazarlar');
}
