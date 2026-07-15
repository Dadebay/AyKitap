import '../strings_base.dart';

/// Strings for [AllSeriesScreen] and [SeriesCard] (series module).
class SeriesStrings {
  SeriesStrings._();

  static String get title => t(tk: 'Seriýalar', ru: 'Серии', tr: 'Seriler');
  static String bookCount(int count) => t(tk: '$count kitap', ru: '$count книг', tr: '$count kitap');
}
