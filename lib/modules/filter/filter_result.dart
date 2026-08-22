import 'controller/filter_controller.dart'
    show BookFormatFilter, SortBy, kDefaultSortBy;

/// Returned to the SearchScreen when "Netijeleri görkez" is pressed — whether
/// any filter is set (drives the red badge) plus every selection that maps
/// onto a `GET /books/all` param, which the search screen folds into its own
/// query rather than replacing it.
class FilterResult {
  final bool active;

  /// Selected [Genre.id] — sent as `genre_id`. Single-select, same as
  /// Search's own genre chip row (the backend only takes one), and this is
  /// exactly that same selection: picking a genre here or on the chip row
  /// updates the one piece of state both places show.
  final int? genreId;

  /// Selected [BookLanguage.id]s — sent as `language_id`.
  final Set<int> languageIds;

  /// Selected file formats — sent as `book_format` (`pdf`/`epub`/`cbz`).
  final Set<BookFormatFilter> formats;

  /// The "Çap senesi" slider's window, as the backend's
  /// `start_year`/`end_year`. Both null while the slider is untouched (its
  /// default range means "any year", so sending it would needlessly drop
  /// books whose `year` the backend doesn't have).
  final int? startYear;
  final int? endYear;

  /// Ordering, split into `sort_by`/`sort_order` on the wire — see
  /// [SortByLabel.apiSortBy]. Unlike the fields above this is never "unset":
  /// it falls back to [kDefaultSortBy], the order the unfiltered screen is
  /// already showing.
  final SortBy sortBy;

  const FilterResult({
    required this.active,
    this.genreId,
    this.languageIds = const {},
    this.formats = const {},
    this.startYear,
    this.endYear,
    this.sortBy = kDefaultSortBy,
  });
}
