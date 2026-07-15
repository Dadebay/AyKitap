import '../strings_base.dart';

/// Strings for [CollectionBooksScreen] (popular module).
class PopularStrings {
  PopularStrings._();

  static String get free => t(tk: 'Mugt', ru: 'Бесплатно', tr: 'Ücretsiz');
  static String priceManat(num amount) => t(tk: '$amount manat', ru: '$amount манат', tr: '$amount manat');
}
