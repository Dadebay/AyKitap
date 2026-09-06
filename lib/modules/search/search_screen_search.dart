part of 'search_screen.dart';

/// Runs the live search — `GET /books/all?search=` in Book mode, `GET
/// /authors/search?search=` in Author mode — and appends load-more pages.
extension _SearchScreenSearch on _SearchScreenState {
  // [loadMore] fetches the next page of book results and appends it — only
  // meaningful in Book mode; author mode still returns its whole page in
  // one go, so [loadMore] is a no-op there. Any other call (a fresh query,
  // a genre/filter/sort change, switching modes) replaces from page 1.
  Future<void> _runSearch({bool loadMore = false}) async {
    if (loadMore && _searchMode == _SearchMode.author) return;
    if (loadMore) {
      if (_searchLoadingMore || !_searchHasMore) return;
    }
    final requestId = ++_searchRequestId;
    _setState(() {
      if (loadMore) {
        _searchLoadingMore = true;
      } else {
        _searching = true;
        _searchError = null;
        _searchPage = 1;
        _searchHasMore = true;
        // A stale load-more (superseded by this fresh request before it
        // resolved) would otherwise leave the footer spinning forever — its
        // own response gets discarded by the requestId check below, so
        // nothing else clears this.
        _searchLoadingMore = false;
        // A new query rebuilds the grid from its top, so the folded-away
        // header has to come back with it — no scroll notification would
        // fire to bring it back on its own.
        _headerCollapsed = false;
      }
    });
    try {
      if (_searchMode == _SearchMode.author) {
        // `GET /authors/search` only takes `search` — genre/language/year
        // don't apply here, and [_shouldShowResults] already keeps this
        // mode from firing without typed text.
        log('🔍 GET /authors/search search="$_query"');
        final authors =
            await AuthorApiService.searchAuthors(search: _query, size: 30);
        if (!mounted || requestId != _searchRequestId) return;
        _setState(() {
          _authorResults = authors;
          _searching = false;
        });
        return;
      }
      final page = loadMore ? _searchPage + 1 : 1;
      log('🔍 GET /books/all search="${_hasQuery ? _query : ''}" genres=$_selectedGenreIds page=$page');
      final results = await BookListApiService.listBooks(
        search: _hasQuery ? _query : null,
        genreIds: _selectedGenreIds,
        languageIds: _filterLanguageIds,
        bookFormats: _filterFormats.map((f) => f.apiValue),
        startYear: _filterStartYear,
        endYear: _filterEndYear,
        sortBy: _filterSort.apiSortBy,
        sortOrder: _filterSort.apiSortOrder,
        page: page,
        size: _SearchScreenState._pageSize,
      );
      if (!mounted || requestId != _searchRequestId) return;
      _setState(() {
        _searchResults = loadMore ? [...?_searchResults, ...results] : results;
        _searchPage = page;
        _searchHasMore = results.length >= _SearchScreenState._pageSize;
        _searching = false;
        _searchLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      _setState(() {
        if (loadMore) {
          _searchLoadingMore = false;
        } else {
          _searchError = e.message;
        }
        _searching = false;
      });
    }
  }
}
