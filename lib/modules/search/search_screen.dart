import 'dart:async';
import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/models/author_detail.dart';
import '../../core/models/genre.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/author_api_service.dart';
import '../../core/services/book_api_service.dart';
import '../../core/services/genre_api_service.dart';
import '../filter/controller/filter_controller.dart' show BookFormatFilter, BookFormatFilterLabel, SortBy, SortByLabel, kDefaultSortBy, kDefaultYearRange;
import '../filter/filter_screen.dart';
import '../home/widgets/catalog_book_card.dart';
import '../../core/localization/strings/search_strings.dart';
import 'widgets/author_result_card.dart';
import 'widgets/quick_chip.dart';

enum _SearchMode { book, author }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // Books per `GET /books/all` page — both the discover grid and book-mode
  // search results page through this. A page shorter than this is taken to
  // mean the backend has nothing left (see `_discoverHasMore`/
  // `_searchHasMore`), which is only approximate for the multi-language/
  // multi-format fan-out (BookApiService._listBooksFanOut merges several
  // per-request pages, so a merged page's length isn't directly comparable)
  // — an acceptable rough edge given how rarely that combination is picked.
  static const _pageSize = 30;

  // Debounced live query — only set once ≥2 chars have been typed.
  String _query = '';
  // Result of the full filter page, if it was applied.
  bool _filterActive = false;
  // Book languages picked on the filter page (`GET /book-languages` ids) —
  // folded into the same `GET /books/all` request as the text query and the
  // genre chip, so language narrows whatever is already showing.
  Set<int> _filterLanguageIds = {};
  // File formats picked on the filter page, sent as `book_format`
  // (`pdf`/`epub`/`cbz`) — same deal: it narrows the current query rather
  // than replacing it.
  Set<BookFormatFilter> _filterFormats = {};
  // "Çap senesi" window picked on the filter page — folded into the same
  // request as `start_year`/`end_year`. Both null while untouched.
  int? _filterStartYear;
  int? _filterEndYear;
  // Ordering picked on the filter page, sent as `sort_by`/`sort_order`.
  // Unlike the filters above this always has a value, and it applies to the
  // discover grid too — sorting isn't a narrowing, so it has something to do
  // even when nothing is being searched for.
  SortBy _filterSort = kDefaultSortBy;

  // True once the grid below has been scrolled away from its top: the page
  // title, the Kitap/Ýazar toggle and the chip row fold away so the covers
  // get the whole screen, and unfold again the moment the grid is back at
  // the top. The search field itself never leaves — losing it mid-scroll
  // would mean scrolling all the way back up just to edit the query.
  bool _headerCollapsed = false;

  // Real genres (`GET /genres/all`, top-level) for the chip row.
  List<Genre>? _genres;
  // Single-select: tapping a genre chip selects it (deselecting whichever
  // was selected before); tapping the already-selected one again clears it.
  // Combined with `_query` in the same search request rather than
  // navigating away, so text + genre can narrow results together.
  int? _selectedGenreId;

  // Which field the typed text matches — the backend treats book-title
  // search (`search=`) and author-name search (`authors=`) as two separate
  // params, not one combined field, so the user picks which one they mean.
  _SearchMode _searchMode = _SearchMode.book;

  // Live search, fired once `_query` settles (see `_onChanged`'s debounce).
  // null = no request has settled yet for the current query (either empty,
  // or still debouncing/in flight); non-null once one has. Book mode fills
  // [_searchResults] (`GET /books/all?search=`); author mode fills
  // [_authorResults] (`GET /authors/search?search=`) — a dedicated
  // author-matching endpoint, so the two modes no longer share one result
  // list.
  List<LibraryBook>? _searchResults;
  List<AuthorSearchResult>? _authorResults;
  bool _searching = false;
  String? _searchError;
  // Book-mode result pagination — author mode isn't paged (`GET
  // /authors/search` returns its whole 30 in one go today).
  int _searchPage = 1;
  bool _searchHasMore = true;
  bool _searchLoadingMore = false;
  // Guards against a slower, older request's response landing after a
  // faster, newer one — only the response whose id still matches this is
  // applied, so a stale result never clobbers what the user is now seeing.
  int _searchRequestId = 0;

  // Shown under the tab bar before the user has typed/selected anything —
  // a default "discover" grid rather than an empty screen. The backend dev
  // asked that this not be a real random order: true randomization has no
  // stable sort underneath it, so the same page boundary can't be
  // reproduced across requests and pagination breaks. [_discoverSort]'s
  // day-of-the-week rotation stands in for it instead — see there.
  List<LibraryBook>? _discoverBooks;
  bool _discoverLoading = false;
  String? _discoverError;
  int _discoverPage = 1;
  bool _discoverHasMore = true;
  bool _discoverLoadingMore = false;
  // Pinned at page 1 (see [_discoverSort]) and reused by every load-more of
  // the same run — re-deriving it on each page instead would let the sort
  // actually change mid-scroll on the rare request that straddles midnight.
  (String, String) _discoverActiveSort = ('created_at', 'DESC');
  // Same stale-response guard as [_searchRequestId] — a sort change (a
  // fresh page-1 load) can otherwise land after an in-flight load-more's
  // response and have that older page's books appended on top of it.
  int _discoverRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadDiscoverBooks();
  }

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
    ('created_at', 'DESC'), // Saturday — ýüklenen wagty, täzeden (the old fixed default)
    ('year', 'DESC'), // Sunday — çap senesi, täzeden
  ];

  /// Only takes over while the filter page's own sort is still untouched —
  /// picking a real sort there (even re-picking today's rotation's own
  /// value) keeps meaning exactly what it says instead of drifting to a
  /// different order tomorrow underneath the user.
  (String, String) get _discoverSort {
    if (_filterSort != kDefaultSortBy) {
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
      setState(() => _discoverLoadingMore = true);
    } else {
      _discoverActiveSort = _discoverSort;
      setState(() {
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
      final books = await BookApiService.listBooks(
        sortBy: _discoverActiveSort.$1,
        sortOrder: _discoverActiveSort.$2,
        page: page,
        size: _pageSize,
      );
      if (!mounted || requestId != _discoverRequestId) return;
      setState(() {
        _discoverBooks = loadMore ? [...?_discoverBooks, ...books] : books;
        _discoverPage = page;
        _discoverHasMore = books.length >= _pageSize;
        _discoverLoading = false;
        _discoverLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _discoverRequestId) return;
      setState(() {
        if (loadMore) {
          _discoverLoadingMore = false;
        } else {
          _discoverError = e.message;
        }
        _discoverLoading = false;
      });
    }
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await GenreApiService.getGenres();
      if (mounted) setState(() => _genres = genres);
    } on ApiException {
      // Best-effort: a broken genre row just doesn't show rather than
      // blocking the rest of the search page.
      if (mounted) setState(() => _genres = const []);
    }
  }

  // Any active filter lights the red badge on the filter button. The genre
  // chips aren't in here on purpose: a selected one is already visibly
  // highlighted in the row right next to the button.
  bool get _hasActiveFilters => _filterActive;

  RangeValues get _filterYearRange => RangeValues(
        (_filterStartYear ?? kDefaultYearRange.start).toDouble(),
        (_filterEndYear ?? kDefaultYearRange.end).toDouble(),
      );

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _hasQuery => _query.length >= 2;
  // A language, format or year filter alone is enough to show results in
  // Book mode — they're real backend filters, same as a genre chip. Sort is
  // deliberately not in this list: it reorders whatever is on screen instead
  // of narrowing it, so on its own it just re-sorts the discover grid.
  // Author mode has no equivalent on `GET /authors/search` (just `search`),
  // so it needs actual typed text.
  bool get _shouldShowResults => _searchMode == _SearchMode.author
      ? _hasQuery
      : _hasQuery || _selectedGenreId != null || _filterLanguageIds.isNotEmpty || _filterFormats.isNotEmpty || _filterStartYear != null || _filterEndYear != null;

  void _onChanged(String value) {
    _debounce?.cancel();
    // Iň az 2 harp ýazylandan soň netijeler peýda bolýar (debounce 300ms).
    if (value.trim().length < 2) {
      // Bumping the request id here too: any in-flight request for the
      // just-abandoned query is now stale, so its response (whenever it
      // lands) gets ignored instead of popping the grid back up.
      _searchRequestId++;
      setState(() => _query = '');
      // A genre/language/year filter can still keep Book mode's results
      // showing — re-run without the (now too-short) text. Author mode has
      // no such standalone filter, so [_shouldShowResults] already says no
      // here and this falls through to clearing.
      if (_shouldShowResults) {
        _runSearch();
      } else if (_searchResults != null || _authorResults != null || _searching) {
        setState(() {
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
      setState(() => _query = term);
      // Fires once per settled query (after the debounce), not per
      // keystroke, so the Analytics console reports what people actually
      // searched for rather than every partial string typed along the way.
      AnalyticsService.instance.logSearch(term);
      _runSearch();
    });
  }

  // Selecting/deselecting a genre chip should search right away — there's
  // no text to debounce, it's a single discrete tap — and combines with
  // whatever's currently in the text field rather than replacing it.
  //
  // A genre is a `GET /books/all` filter and nothing else, so tapping one
  // while the Ýazar tab is showing is unambiguously "show me books in this
  // genre": the toggle slides back to Kitap along with the tap instead of
  // lighting up a chip that couldn't change a single author result.
  void _toggleGenre(Genre genre) {
    _debounce?.cancel();
    setState(() {
      _selectedGenreId = _selectedGenreId == genre.id ? null : genre.id;
      _searchMode = _SearchMode.book;
    });
    if (_shouldShowResults) {
      _runSearch();
    } else {
      _searchRequestId++;
      setState(() {
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
    setState(() => _searchMode = mode);
    if (_shouldShowResults) {
      _runSearch();
    } else {
      _searchRequestId++;
      setState(() {
        _searchResults = null;
        _authorResults = null;
        _searching = false;
        _searchError = null;
        _headerCollapsed = false;
      });
    }
  }

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
    setState(() {
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
        final authors = await AuthorApiService.searchAuthors(search: _query, size: 30);
        if (!mounted || requestId != _searchRequestId) return;
        setState(() {
          _authorResults = authors;
          _searching = false;
        });
        return;
      }
      final page = loadMore ? _searchPage + 1 : 1;
      final results = await BookApiService.listBooks(
        search: _hasQuery ? _query : null,
        genreId: _selectedGenreId,
        languageIds: _filterLanguageIds,
        bookFormats: _filterFormats.map((f) => f.apiValue),
        startYear: _filterStartYear,
        endYear: _filterEndYear,
        sortBy: _filterSort.apiSortBy,
        sortOrder: _filterSort.apiSortOrder,
        page: page,
        size: _pageSize,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = loadMore ? [...?_searchResults, ...results] : results;
        _searchPage = page;
        _searchHasMore = results.length >= _pageSize;
        _searching = false;
        _searchLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        if (loadMore) {
          _searchLoadingMore = false;
        } else {
          _searchError = e.message;
        }
        _searching = false;
      });
    }
  }

  // The search bar's own "×" — clears the text *and* whichever genre chip
  // is selected, so the whole filter (not just the typed part of it) resets.
  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    _searchRequestId++;
    setState(() {
      _query = '';
      _selectedGenreId = null;
      _searchResults = null;
      _authorResults = null;
      _searching = false;
      _searchError = null;
    });
  }

  Future<void> _openFilter() async {
    final res = await context.push<FilterResult>(FilterScreen(
      initialGenreId: _selectedGenreId,
      initialLanguageIds: _filterLanguageIds,
      initialFormats: _filterFormats,
      initialYearRange: _filterYearRange,
      initialSortBy: _filterSort,
    ));
    if (res == null || !mounted) return;
    _debounce?.cancel();
    final sortChanged = res.sortBy != _filterSort;
    setState(() {
      _filterActive = res.active;
      // Same selection the chip row shows/sets — picking a genre inside the
      // filter page just updates it from the other side.
      _selectedGenreId = res.genreId;
      // A genre is a Book-mode filter (see [_toggleGenre]) — picking one on
      // the filter page while Ýazar is showing means the same thing a chip
      // tap would.
      if (_selectedGenreId != null) _searchMode = _SearchMode.book;
      _filterLanguageIds = res.languageIds;
      _filterFormats = res.formats;
      _filterStartYear = res.startYear;
      _filterEndYear = res.endYear;
      _filterSort = res.sortBy;
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
      setState(() {
        _searchResults = null;
        _authorResults = null;
        _searching = false;
        _searchError = null;
        _headerCollapsed = false;
      });
    }
  }

  // Collapse as soon as the grid leaves its top, expand only when it's back
  // there — matching "scroll down to read, scroll up to the start to get the
  // controls back" rather than reacting to every flick of direction.
  //
  // The threshold is a few pixels rather than 0 so an overscroll bounce (or
  // a keyboard-driven relayout) doesn't strobe the header, and horizontal
  // notifications from the chip row are ignored outright.
  bool _onResultsScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final collapsed = notification.metrics.pixels > 12;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
    // Fetch the next page a screen or so before the actual bottom, so it's
    // already there by the time the user reaches it rather than after.
    // Whichever grid is on screen loads more; the load calls themselves
    // no-op when one's already in flight or there's nothing left.
    if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 600) {
      if (_shouldShowResults) {
        _runSearch(loadMore: true);
      } else {
        _loadDiscoverBooks(loadMore: true);
      }
    }
    return false;
  }

  /// Wraps a header row so it fades *and* gives its height back to the grid
  /// as it goes — [AnimatedCrossFade] against an empty box animates both,
  /// which a plain [AnimatedOpacity] wouldn't (it would leave a hole).
  Widget _collapsibleHeader({required Widget child}) {
    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState: _headerCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 260),
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      sizeCurve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                child: Text(SearchStrings.title, style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800)),
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
                child: _shouldShowResults ? _buildSearchResults() : _buildDiscoverGrid(),
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
              Text(_searchError!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _runSearch,
                child: Text(SearchStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final results = _searchResults ?? const [];
    final authorResults = _authorResults ?? const [];
    final isEmpty = _searchMode == _SearchMode.author ? authorResults.isEmpty : results.isEmpty;
    if (isEmpty) {
      final isDark = AppTheme.instance.isDark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    isDark ? 'assets/images/search_empty_dark.webp' : 'assets/images/search_empty_light.webp',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(SearchStrings.noResults, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
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
    return _bookGrid(
      books: results,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      loadingMore: _searchLoadingMore,
    );
  }

  // Shared by both the search-results grid and the discover grid — three
  // columns of covers, plus a spinner row at the bottom while the next page
  // (see [_onResultsScroll]) is in flight. A [CustomScrollView] rather than
  // a plain [GridView.builder] so that spinner can sit as its own sliver
  // below the grid instead of needing an off-by-one extra grid cell for it.
  Widget _bookGrid({required List<LibraryBook> books, required EdgeInsets padding, required bool loadingMore}) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => CatalogBookCard(book: books[i], width: double.infinity, coverHeight: 170, margin: EdgeInsets.zero),
              childCount: books.length,
            ),
          ),
        ),
        if (loadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ),
      ],
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
              Text(_discoverError!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadDiscoverBooks,
                child: Text(SearchStrings.retry, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final books = _discoverBooks ?? const [];
    if (books.isEmpty) return const SizedBox.shrink();
    return _bookGrid(
      books: books,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      loadingMore: _discoverLoadingMore,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const SizedBox(width: 14),
            HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.grey2, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: SearchStrings.searchHint,
                  hintStyle: TextStyle(color: AppColors.grey3, fontSize: 14.5),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clearQuery,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.grey2, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // "Kitap" / "Ýazar" pill — governs whether the typed text goes to the
  // backend's `search` (title) or `authors` (author name) param.
  //
  // The stock iOS control rather than a hand-rolled one: its thumb slides
  // between segments with the real spring curve, shrinks under the finger,
  // and can be *dragged* across — behaviour that a plain AnimatedContainer
  // per segment (which just cross-faded two background colors) can't
  // reproduce. Colors are overridden to the app's own, so only the motion is
  // Cupertino.
  Widget _buildSearchModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The control sizes every segment to its widest child and then lets
          // the whole box stretch, which would leave both pills huddled at
          // the left of a full-width row. Handing the labels half the row
          // each is what makes the thumb travel the full distance — the
          // control clamps anything wider back to an exact half.
          final segmentWidth = (constraints.maxWidth - 12) / 2;
          return CupertinoSlidingSegmentedControl<_SearchMode>(
            groupValue: _searchMode,
            backgroundColor: AppColors.card,
            thumbColor: AppColors.primary,
            padding: const EdgeInsets.all(3),
            // Non-null only when the value actually changes, and
            // [_setSearchMode] no-ops on a repeat anyway.
            onValueChanged: (mode) => _setSearchMode(mode ?? _searchMode),
            children: {
              _SearchMode.book: _searchModeLabel(SearchStrings.searchByBook, _SearchMode.book, segmentWidth),
              _SearchMode.author: _searchModeLabel(SearchStrings.searchByAuthor, _SearchMode.author, segmentWidth),
            },
          );
        },
      ),
    );
  }

  Widget _searchModeLabel(String label, _SearchMode mode, double width) {
    final selected = _searchMode == mode;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          label,
          textAlign: TextAlign.center,
          // The thumb carries the motion; the label only has to stay legible
          // against whichever color ends up under it.
          style: TextStyle(color: selected ? Colors.white : AppColors.grey2, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildChipsRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Filter button (opens the full filter page) with a red badge
          // whenever any filter is active.
          GestureDetector(
            onTap: _openFilter,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal, color: AppColors.primary, size: 20),
                ),
                if (_hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Real genres (`GET /genres/all`) — tapping one selects it in
          // place (combined with any text query) rather than navigating
          // away; tapping the selected one again clears it.
          //
          // Shown in both modes. `GET /authors/search` takes nothing but
          // `search`, so a genre can't narrow author results — but hiding
          // the row in Ýazar mode made it jump in and out as the toggle
          // moved, and left the user no way back to a genre from there.
          // Instead the chips stay put and [_toggleGenre] switches the
          // toggle back to Kitap, where the tap actually means something.
          for (final genre in _genres ?? const []) ...[
            QuickChip(label: genre.name, selected: _selectedGenreId == genre.id, onTap: () => _toggleGenre(genre)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
