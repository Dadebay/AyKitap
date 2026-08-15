import 'package:flutter/material.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../../../core/models/book_language.dart';
import '../../../core/models/genre.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_language_api_service.dart';
import '../../../core/services/genre_api_service.dart';
import '../filter_result.dart';

enum SortBy { name, publishNewOld, publishOldNew, uploadNewOld }

extension SortByLabel on SortBy {
  String get label {
    switch (this) {
      case SortBy.name:
        return FilterStrings.sortByName;
      case SortBy.publishNewOld:
        return FilterStrings.sortByPublishNewOld;
      case SortBy.publishOldNew:
        return FilterStrings.sortByPublishOldNew;
      case SortBy.uploadNewOld:
        return FilterStrings.sortByUploadNewOld;
    }
  }

  /// `GET /books/all?sort_by=` — the backend takes `created_at`, `name` or
  /// `year`, so each option here is really a (field, direction) pair rather
  /// than a value of its own.
  String get apiSortBy {
    switch (this) {
      case SortBy.name:
        return 'name';
      case SortBy.publishNewOld:
      case SortBy.publishOldNew:
        return 'year';
      case SortBy.uploadNewOld:
        return 'created_at';
    }
  }

  /// The direction half of the pair — `GET /books/all?sort_order=`.
  String get apiSortOrder {
    switch (this) {
      case SortBy.name:
      case SortBy.publishOldNew:
        return 'ASC';
      case SortBy.publishNewOld:
      case SortBy.uploadNewOld:
        return 'DESC';
    }
  }
}

/// What [SearchScreen] shows before anything is filtered (its "discover"
/// grid) and therefore what the filter page opens on, so the sort section
/// reflects the order actually on screen instead of claiming A→Z.
///
/// Newest-uploaded-first stands in for a random shuffle deliberately: the
/// backend dev flagged that true randomization has no stable sort under it,
/// so a page boundary can't be reproduced between requests and pagination
/// breaks.
const kDefaultSortBy = SortBy.uploadNewOld;

// Selection state keys off this enum rather than the display label text —
// labels are locale-dependent (via FilterStrings), so keying a Set<String>
// off them would silently drop selections when the language changes mid-session.
// (Book languages are the exception: those are real backend rows, so they're
// keyed off their `id` — see [selectedLanguageIds].)
// Only the three formats `GET /books/all?book_format=` accepts. MOBI used to
// be offered here, but nothing on the backend can filter for it, so the chip
// could only ever return an unfiltered list.
enum BookFormatFilter { epub, pdf, cbz }

extension BookFormatFilterLabel on BookFormatFilter {
  String get label {
    switch (this) {
      case BookFormatFilter.epub:
        return FilterStrings.formatEpub;
      case BookFormatFilter.pdf:
        return FilterStrings.formatPdf;
      case BookFormatFilter.cbz:
        return FilterStrings.formatCbzManga;
    }
  }

  /// What goes on the wire as `book_format`.
  String get apiValue => name;
}

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
