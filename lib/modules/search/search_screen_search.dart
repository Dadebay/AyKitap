part of 'search_screen.dart';

/// Runs the live search — `GET /books/all?search=` in Book mode, `GET
/// /authors/search?search=` in Author mode — and appends load-more pages.
extension _SearchScreenSearch on _SearchScreenState {
  // [loadMore] fetches the next page of results and appends it — both modes
  // page now. Any other call (a fresh query, a genre/filter/sort change,
  // switching modes) replaces from page 1.
  Future<void> _runSearch({bool loadMore = false}) async {
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
        final authorPage = loadMore ? _searchPage + 1 : 1;
        log('🔍 GET /authors/search search="$_query" page=$authorPage');
        final authors = await AuthorApiService.searchAuthors(
          search: _query,
          page: authorPage,
          size: _SearchScreenState._pageSize,
        );
        if (!mounted || requestId != _searchRequestId) return;
        final (merged, added) =
            mergeAuthorPage(loadMore ? _authorResults : null, authors);
        _setState(() {
          _authorResults = merged;
          _searchPage = authorPage;
          // See [mergeAuthorPage] for why this counts new ids rather than
          // comparing the page's length against the size asked for.
          _searchHasMore = added > 0;
          _searching = false;
          _searchLoadingMore = false;
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
