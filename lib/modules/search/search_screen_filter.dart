part of 'search_screen.dart';

/// Opens the full [FilterScreen] and folds its result back into this
/// screen's language/format/year/sort state.
extension _SearchScreenFilter on _SearchScreenState {
  Future<void> _openFilter() async {
    final res = await context.push<FilterResult>(FilterScreen(
      initialGenreIds: _selectedGenreIds,
      initialLanguageIds: _filterLanguageIds,
      initialFormats: _filterFormats,
      initialYearRange: _filterYearRange,
      initialSortBy: _filterSort,
    ));
    if (res == null || !mounted) return;
    _debounce?.cancel();
    // Also counts as changed the first time the filter page is applied even
    // if [res.sortBy] happens to already equal [_filterSort]: before this,
    // the discover grid was still following the daily rotation (see
    // [_discoverSort]), so confirming the same-looking value is still a real
    // change from "rotating" to "pinned".
    final sortChanged = res.sortBy != _filterSort || !_sortChosenByUser;
    _setState(() {
      _filterActive = res.active;
      // Same selection the chip row shows/sets — picking genres inside the
      // filter page just updates it from the other side.
      _selectedGenreIds = res.genreIds;
      // A genre is a Book-mode filter (see [_toggleGenre]) — picking one on
      // the filter page while Awtor is showing means the same thing a chip
      // tap would.
      if (_selectedGenreIds.isNotEmpty) _searchMode = _SearchMode.book;
      _filterLanguageIds = res.languageIds;
      _filterFormats = res.formats;
      _filterStartYear = res.startYear;
      _filterEndYear = res.endYear;
      _filterSort = res.sortBy;
      _sortChosenByUser = true;
    });
    // Sort applies to the discover grid as well, and that list was fetched
    // in the old order — so a new sort means re-fetching it, whether or not
    // there's a search on screen right now.
    if (sortChanged) _loadDiscoverBooks();
    // The language/format/year/sort parts of the filter all change the
    // actual query, so applying it re-runs the search straight away (or
    // tears the results down if nothing is left to search for).
    if (_shouldShowResults) {
      _runSearch();
    } else {
      _searchRequestId++;
      _setState(() {
        _searchResults = null;
        _authorResults = null;
        _searching = false;
        _searchError = null;
        _headerCollapsed = false;
      });
    }
  }
}
