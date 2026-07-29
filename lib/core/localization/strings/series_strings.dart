import '../strings_base.dart';

/// Strings for [CatalogSeriesCard] (the `card_type: "card_3"` collection card).
class SeriesStrings {
  SeriesStrings._();

  static String bookCount(int count) => t(tk: '$count kitap', ru: '$count книг', tr: '$count kitap');
}
