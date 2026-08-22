import 'package:flutter/material.dart';
import '../../../core/models/book_language.dart';
import '../../../core/models/genre.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_language_api_service.dart';
import '../../../core/services/genre_api_service.dart';
import '../filter_result.dart';
import 'filter_enums.dart';

export 'filter_enums.dart';

const kDefaultYearRange = RangeValues(1990, 2026);

/// Owns every bit of selection state on [FilterScreen] — quick chips,
/// language/format multi-select, year range, sort order, and which
/// collapsible section is open — so the screen itself just renders it.
class FilterController extends ChangeNotifier {
  /// The `initial*` arguments re-select whatever the caller ([SearchScreen])
  /// already has applied, so reopening the filter shows the current state
  /// instead of an empty form.
  FilterController({
    int? initialGenreId,
    Set<int> initialLanguageIds = const {},
    Set<BookFormatFilter> initialFormats = const {},
    RangeValues? initialYearRange,
    SortBy? initialSortBy,
  })  : selectedGenreId = initialGenreId,
        selectedLanguageIds = {...initialLanguageIds},
        selectedFormats = {...initialFormats},
        yearRange = initialYearRange ?? kDefaultYearRange,
        sortBy = initialSortBy ?? kDefaultSortBy {
    loadGenres();
    loadLanguages();
  }

  /// Top-level genres from `GET /genres/all` — the same list Search's own
  /// chip row shows, so picking one here or there is one selection either
  /// way. Null until the call settles.
  List<Genre>? genres;
  bool genresFailed = false;

  /// Single-select, same as the chip row: the backend's `genre_id` only
  /// ever takes one value.
  int? selectedGenreId;

  /// Book languages from `GET /book-languages`; null until the call
  /// settles. The chips render off this rather than a hardcoded list, so a
  /// language added on the backend shows up without an app release.
  List<BookLanguage>? languages;
  bool languagesFailed = false;

  /// Selected [BookLanguage.id]s — what goes to `GET /books/all` as
  /// `language_id`.
  final Set<int> selectedLanguageIds;

  /// Selected file formats — what goes to `GET /books/all` as `book_format`.
  final Set<BookFormatFilter> selectedFormats;

  /// "Çap senesi" window. Only counts as a filter once it differs from
  /// [kDefaultYearRange] — see [hasYearFilter].
  RangeValues yearRange;
  SortBy sortBy;

  bool get hasYearFilter => yearRange != kDefaultYearRange;

  // Which collapsible sections are open.
  final Set<String> expanded = {};

  bool get hasActiveFilters =>
      selectedLanguageIds.isNotEmpty ||
      selectedFormats.isNotEmpty ||
      hasYearFilter ||
      sortBy != kDefaultSortBy;

  /// Summary line for the collapsed "Dil" section — the picked languages'
  /// names, in the order the backend returned them.
  String get selectedLanguagesLabel => (languages ?? const <BookLanguage>[])
      .where((l) => selectedLanguageIds.contains(l.id))
      .map((l) => l.label)
      .join(', ');

  /// Summary line for the collapsed "Žanr" section.
  String? get selectedGenreLabel {
    for (final g in genres ?? const <Genre>[]) {
      if (g.id == selectedGenreId) return g.name;
    }
    return null;
  }

  Future<void> loadGenres() async {
    genresFailed = false;
    notifyListeners();
    try {
      genres = await GenreApiService.getGenres();
    } on ApiException {
      // Same best-effort stance as the language load: a failed fetch shows
      // a retry inside the section instead of blocking the whole page.
      genres = const [];
      genresFailed = true;
    }
    notifyListeners();
  }

  Future<void> loadLanguages() async {
    languagesFailed = false;
    notifyListeners();
    try {
      languages = await BookLanguageApiService.getLanguages();
    } on ApiException {
      // Same best-effort stance as Search's genre row: a failed load shows a
      // retry inside the section instead of blocking the whole filter page.
      languages = const [];
      languagesFailed = true;
    }
    notifyListeners();
  }

  /// Single-select, same toggle behaviour as Search's own genre chip row:
  /// tapping the already-selected genre clears it instead of no-opping.
  void toggleGenre(Genre genre) {
    selectedGenreId = selectedGenreId == genre.id ? null : genre.id;
    notifyListeners();
  }

  void toggleLanguage(BookLanguage lang) {
    selectedLanguageIds.contains(lang.id)
        ? selectedLanguageIds.remove(lang.id)
        : selectedLanguageIds.add(lang.id);
    notifyListeners();
  }

  void toggleFormat(BookFormatFilter format) {
    selectedFormats.contains(format)
        ? selectedFormats.remove(format)
        : selectedFormats.add(format);
    notifyListeners();
  }

  void setYearRange(RangeValues v) {
    yearRange = v;
    notifyListeners();
  }

  void setSortBy(SortBy s) {
    sortBy = s;
    notifyListeners();
  }

  void toggleExpanded(String id) {
    expanded.contains(id) ? expanded.remove(id) : expanded.add(id);
    notifyListeners();
  }

  void clear() {
    selectedGenreId = null;
    selectedLanguageIds.clear();
    selectedFormats.clear();
    yearRange = kDefaultYearRange;
    sortBy = kDefaultSortBy;
    notifyListeners();
  }

  /// Every selection here maps onto a real `GET /books/all` param —
  /// `genre_id`, `language_id`, `book_format`, `start_year`/`end_year` and
  /// `sort_by`/`sort_order` — which [SearchScreen] re-runs its query with.
  FilterResult buildResult() => FilterResult(
        active: hasActiveFilters,
        genreId: selectedGenreId,
        languageIds: {...selectedLanguageIds},
        formats: {...selectedFormats},
        startYear: hasYearFilter ? yearRange.start.round() : null,
        endYear: hasYearFilter ? yearRange.end.round() : null,
        sortBy: sortBy,
      );
}
