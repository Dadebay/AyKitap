part of 'search_screen.dart';

/// The pre-search "discover" grid: `GET /books/all` with a daily-rotating
/// default sort (see [_discoverSort]) instead of the app asking the backend
/// for genuine randomness, which would break pagination (no stable order
/// underneath it to page against).
extension _SearchScreenDiscover on _SearchScreenState {
  // One (sort_by, sort_order) pair per weekday — the team's fix for the
  // discover grid looking too static without ever breaking pagination (see
  // [_discoverBooks]'s comment): true per-request random has no stable
  // order underneath it, so instead the *default* order changes once a day,
  // cycling through every sort the filter page itself offers plus their
  // reverses. Stable all day (so `page`/`size` still lines up request to
  // request), different from the day before — "looks random" over repeat
  // visits without the backend ever being asked for one.
  static const _discoverDailySorts = [
    ('name', 'ASC'), // Monday — ady boýunça (A→Z)
    ('year', 'DESC'), // Tuesday — çap senesi, täzeden
    ('created_at', 'ASC'), // Wednesday — ýüklenen wagty, köneden
    ('name', 'DESC'), // Thursday — ady boýunça (Z→A)
    ('year', 'ASC'), // Friday — çap senesi, köneden
    (
      'created_at',
      'DESC'
    ), // Saturday — ýüklenen wagty, täzeden (the old fixed default)
    ('year', 'DESC'), // Sunday — çap senesi, täzeden
  ];

  /// Only takes over while the filter page's own sort is still untouched —
  /// picking a real sort there (even re-picking today's rotation's own
  /// value, or [kDefaultSortBy] itself) keeps meaning exactly what it says
  /// instead of drifting to a different order tomorrow underneath the user.
  /// Keyed off [_sortChosenByUser] rather than `_filterSort !=
  /// kDefaultSortBy`: [kDefaultSortBy] is itself a selectable option
  /// ("Ýüklenen wagty (täzeden köne)"), so that comparison couldn't tell
  /// "never opened the filter page" apart from "opened it and picked the
  /// option that happens to match the default".
  (String, String) get _discoverSort {
    if (_sortChosenByUser) {
      return (_filterSort.apiSortBy, _filterSort.apiSortOrder);
    }
    final weekday = DateTime.now().weekday; // 1 (Mon) .. 7 (Sun)
    return _discoverDailySorts[(weekday - 1) % _discoverDailySorts.length];
  }

  // [loadMore] fetches the next page and appends it; the default (a fresh
  // call, or the sort changing) replaces the grid from page 1.
  Future<void> _loadDiscoverBooks({bool loadMore = false}) async {
    if (loadMore) {
      if (_discoverLoadingMore || !_discoverHasMore) return;
    }
    final requestId = ++_discoverRequestId;
    if (loadMore) {
      _setState(() => _discoverLoadingMore = true);
    } else {
      _discoverActiveSort = _discoverSort;
      _setState(() {
        _discoverLoading = true;
        _discoverError = null;
        _discoverPage = 1;
        _discoverHasMore = true;
        // See [_searchLoadingMore]'s reset in [_runSearch] — same stale
        // in-flight-load-more concern.
        _discoverLoadingMore = false;
      });
    }
    final page = loadMore ? _discoverPage + 1 : 1;
    try {
      final books = await BookListApiService.listBooks(
        sortBy: _discoverActiveSort.$1,
        sortOrder: _discoverActiveSort.$2,
        page: page,
        size: _SearchScreenState._pageSize,
      );
      if (!mounted || requestId != _discoverRequestId) return;
      _setState(() {
        _discoverBooks = loadMore ? [...?_discoverBooks, ...books] : books;
        _discoverPage = page;
        _discoverHasMore = books.length >= _SearchScreenState._pageSize;
        _discoverLoading = false;
        _discoverLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _discoverRequestId) return;
      _setState(() {
        if (loadMore) {
          _discoverLoadingMore = false;
        } else {
          _discoverError = e.message;
        }
        _discoverLoading = false;
      });
    }
  }
}
