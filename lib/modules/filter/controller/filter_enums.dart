import '../../../core/localization/strings/filter_strings.dart';

/// [FilterController]'s sort/format value types — split out to keep that
/// file under the 200-line limit. Re-exported from `filter_controller.dart`
/// so existing imports of that file keep seeing these unchanged.
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
