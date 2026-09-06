part of 'search_screen.dart';

/// Text-field, genre-chip and mode-toggle handling — everything that changes
/// what the user is searching for (as opposed to running the search itself,
/// see search_screen_search.dart).
extension _SearchScreenQuery on _SearchScreenState {
  Future<void> _loadGenres() async {
    try {
      final genres = await GenreApiService.getGenres();
      if (mounted) _setState(() => _genres = genres);
    } on ApiException {
      // Best-effort: a broken genre row just doesn't show rather than
      // blocking the rest of the search page.
      if (mounted) _setState(() => _genres = const []);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Iň az 2 harp ýazylandan soň netijeler peýda bolýar (debounce 300ms).
    if (value.trim().length < 2) {
      // Bumping the request id here too: any in-flight request for the
      // just-abandoned query is now stale, so its response (whenever it
      // lands) gets ignored instead of popping the grid back up.
      _searchRequestId++;
      _setState(() => _query = '');
      // A genre/language/year filter can still keep Book mode's results
      // showing — re-run without the (now too-short) text. Author mode has
      // no such standalone filter, so [_shouldShowResults] already says no
      // here and this falls through to clearing.
      if (_shouldShowResults) {
        _runSearch();
      } else if (_searchResults != null ||
          _authorResults != null ||
          _searching) {
        _setState(() {
          _searchResults = null;
          _authorResults = null;
          _searching = false;
          _searchError = null;
          _headerCollapsed = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final term = value.trim();
      _setState(() => _query = term);
      // Fires once per settled query (after the debounce), not per
      // keystroke, so the Analytics console reports what people actually
      // searched for rather than every partial string typed along the way.
      AnalyticsService.instance.logSearch(term);
      _runSearch();
    });
  }

  // Selecting/deselecting a genre chip should search right away — there's
  // no text to debounce, it's a single discrete tap — and combines with
  // whatever's currently in the text field (and whichever other genre chips
  // are already on) rather than replacing either.
  //
  // A genre is a `GET /books/all` filter and nothing else, so tapping one
  // while the Awtor tab is showing is unambiguously "show me books in this
  // genre": the toggle slides back to Kitap along with the tap instead of
  // lighting up a chip that couldn't change a single author result.
  void _toggleGenre(Genre genre) {
    _debounce?.cancel();
    _setState(() {
      _selectedGenreIds.contains(genre.id)
          ? _selectedGenreIds.remove(genre.id)
          : _selectedGenreIds.add(genre.id);
      _searchMode = _SearchMode.book;
    });
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

  // Switching modes re-interprets whatever's already typed/selected rather
  // than clearing it — e.g. typing an author's name in Book mode, getting
  // nothing, then flipping to Author mode should just work.
  void _setSearchMode(_SearchMode mode) {
    if (_searchMode == mode) return;
    _debounce?.cancel();
    _setState(() => _searchMode = mode);
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
      // Nothing typed yet — each mode falls through to its own discover
      // grid. Author mode retries on every switch back to it as long as
      // [_discoverAuthors] is still null (see [_loadDiscoverAuthors]'s own
      // cache check) — Book mode's [_discoverBooks] only ever got the one
      // shot at `initState`, so a transient failure/empty response on that
      // very first load previously had no way back short of restarting the
      // app, even though tapping over to Author and back looked like it
      // should retry the same way.
      if (mode == _SearchMode.author) {
        _loadDiscoverAuthors();
      } else if (_discoverBooks == null || _discoverBooks!.isEmpty) {
        _loadDiscoverBooks();
      }
    }
  }

  // The search bar's own "×" — clears the text *and* whichever genre chip
  // is selected, so the whole filter (not just the typed part of it) resets.
  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    _searchRequestId++;
    _setState(() {
      _query = '';
      _selectedGenreIds = {};
      _searchResults = null;
      _authorResults = null;
      _searching = false;
      _searchError = null;
    });
  }
}
