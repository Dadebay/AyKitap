part of 'search_screen.dart';

/// The screen's top-level widget tree, the results/discover grids and the
/// shared grid builder they both use. Search-bar/mode-toggle/chips-row UI
/// lives in search_screen_controls.dart.
extension _SearchScreenBody on _SearchScreenState {
  /// Both grids on this screen end above the wheel rather than behind it —
  /// [MainNavScreen]'s Scaffold uses `extendBody`, so the bar is painted over
  /// this content. See [WheelNavBar.clearance]; the four hardcoded bottoms
  /// this replaced (20 and 60) were each short of it.
  EdgeInsets _gridPadding(
    BuildContext context, {
    double bottomSpacing = 16,
  }) =>
      EdgeInsets.fromLTRB(
          20, 8, 20, WheelNavBar.clearance(context) + bottomSpacing);

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Everything but the search field folds away once the grid is
            // scrolled — see [_onResultsScroll].
            _collapsibleHeader(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(SearchStrings.title,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            _buildSearchBar(),
            _collapsibleHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSearchModeToggle(),
                  const SizedBox(height: 12),
                  _buildChipsRow(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onResultsScroll,
                child: _shouldShowResults
                    ? _buildSearchResults()
                    // [_buildDiscoverGrid] is book-only — Author mode with
                    // nothing typed yet gets its own discover grid instead
                    // of falling through to book covers.
                    : _searchMode == _SearchMode.author
                        ? _buildAuthorDiscoverGrid()
                        : _buildDiscoverGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_searchError != null) {
      return SearchErrorState(
        message: _searchError!,
        onRetry: _runSearch,
      );
    }
    final results = _searchResults ?? const [];
    final authorResults = _authorResults ?? const [];
    final isEmpty = _searchMode == _SearchMode.author
        ? authorResults.isEmpty
        : results.isEmpty;
    // Both modes get the same state: a reader who searched an author we do
    // not carry is missing that author's books, which is the same request.
    if (isEmpty) return const SearchNoResultsState();
    // Author mode: `GET /authors/search` hands back matching authors
    // directly (id/name/image/book_count), so these render straight from
    // [_authorResults] rather than being derived from book results.
    if (_searchMode == _SearchMode.author) {
      return AuthorResultGrid(
        authors: authorResults,
        padding: _gridPadding(context),
        loadingMore: _searchLoadingMore,
        controller: _authorGridScroll,
      );
    }
    // CatalogBookCard already navigates to CatalogBookDetailScreen on tap
    // (like every other real-book grid in the app) — no extra wrapper here.
    return SearchResultGrid(
      books: results,
      // Keep 30 px of visible breathing room between the suggestion action
      // and the wheel navigation once the list is scrolled to its end.
      padding: _gridPadding(context, bottomSpacing: 30),
      loadingMore: _searchLoadingMore,
      controller: _bookGridScroll,
      // A close-but-not-exact match is still a missing book. Keep the same
      // request action used by the zero-results state reachable underneath
      // non-empty title-search results too.
      footer: const SuggestBookButton(),
    );
  }

  // The pre-search state: `GET /books/all?sort_by=created_at&sort_order=DESC`
  // (see [_loadDiscoverBooks]) rendered in the same 3-column grid as real
  // search results, so the pill toggle/genre chips above it stay in place
  // instead of the screen going blank.
  Widget _buildDiscoverGrid() {
    if (_discoverLoading && _discoverBooks == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_discoverError != null && _discoverBooks == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_discoverError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadDiscoverBooks,
                child: Text(SearchStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final books = _discoverBooks ?? const [];
    // Not a legitimate "empty catalogue" state — the discover grid has no
    // filters applied, so an empty result here means the fetch raced or
    // glitched rather than that there's genuinely nothing to show. Offering
    // retry (instead of the blank space this used to render) is what
    // switching to Author mode and back already did by accident, since
    // [_loadDiscoverAuthors] retries on its own — this closes the same gap
    // for the case where Book mode was never left in the first place.
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(SearchStrings.noResults,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadDiscoverBooks,
                child: Text(SearchStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    return SearchResultGrid(
      books: books,
      padding: _gridPadding(context),
      loadingMore: _discoverLoadingMore,
      controller: _bookGridScroll,
    );
  }

  /// Author mode's counterpart of [_buildDiscoverGrid] — a default author
  /// list (see [_loadDiscoverAuthors]) shown before any name is typed,
  /// rather than either falling through to the book grid or sitting empty.
  Widget _buildAuthorDiscoverGrid() {
    if (_discoverAuthorsLoading && _discoverAuthors == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_discoverAuthorsError != null && _discoverAuthors == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_discoverAuthorsError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _loadDiscoverAuthors(retry: true),
                child: Text(SearchStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final authors = _discoverAuthors ?? const [];
    // Only reachable if the backend genuinely has zero authors — the typed-
    // search prompt still applies then, since there's nothing to browse.
    if (authors.isEmpty) return _buildAuthorSearchPrompt();
    return AuthorResultGrid(
      authors: authors,
      padding: _gridPadding(context),
      loadingMore: _discoverAuthorsLoadingMore,
      controller: _authorGridScroll,
    );
  }

  Widget _buildAuthorSearchPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Center(
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUserSearch01,
                      color: AppColors.primary,
                      size: 28)),
            ),
            const SizedBox(height: 16),
            Text(SearchStrings.authorSearchPrompt,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
