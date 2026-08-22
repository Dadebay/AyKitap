part of 'search_screen.dart';

/// The screen's top-level widget tree, the results/discover grids and the
/// shared grid builder they both use. Search-bar/mode-toggle/chips-row UI
/// lives in search_screen_controls.dart.
extension _SearchScreenBody on _SearchScreenState {
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_searchError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _runSearch,
                child: Text(SearchStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final results = _searchResults ?? const [];
    final authorResults = _authorResults ?? const [];
    final isEmpty = _searchMode == _SearchMode.author
        ? authorResults.isEmpty
        : results.isEmpty;
    if (isEmpty) {
      final isDark = AppTheme.instance.isDark;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    isDark
                        ? 'assets/images/search_empty_dark.webp'
                        : 'assets/images/search_empty_light.webp',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(SearchStrings.noResults,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 15)),
            ],
          ),
        ),
      );
    }
    // Author mode: `GET /authors/search` hands back matching authors
    // directly (id/name/image/book_count), so these render straight from
    // [_authorResults] rather than being derived from book results.
    if (_searchMode == _SearchMode.author) {
      // A list of full-width rows rather than Home's square avatar grid: a
      // search hit is chosen by reading the name, and [AuthorResultCard]
      // also surfaces the `book_count` the endpoint returns, which the
      // grid cell had no room for.
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: authorResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => AuthorResultCard(author: authorResults[i]),
      );
    }
    // CatalogBookCard already navigates to CatalogBookDetailScreen on tap
    // (like every other real-book grid in the app) — no extra wrapper here.
    return SearchResultGrid(
      books: results,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      loadingMore: _searchLoadingMore,
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
    if (books.isEmpty) return const SizedBox.shrink();
    return SearchResultGrid(
      books: books,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      loadingMore: _discoverLoadingMore,
    );
  }
}
