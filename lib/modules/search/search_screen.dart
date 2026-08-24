import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/localization/strings/search_strings.dart';
import '../../core/models/author_detail.dart';
import '../../core/models/genre.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/author_api_service.dart';
import '../../core/services/book_list_api_service.dart';
import '../../core/services/genre_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../filter/controller/filter_controller.dart'
    show
        BookFormatFilter,
        BookFormatFilterLabel,
        SortBy,
        SortByLabel,
        kDefaultSortBy,
        kDefaultYearRange;
import '../filter/filter_screen.dart';
import 'widgets/author_result_card.dart';
import 'widgets/quick_chip.dart';
import 'widgets/search_result_grid.dart';

part 'search_screen_body.dart';
part 'search_screen_controls.dart';
part 'search_screen_discover.dart';
part 'search_screen_filter.dart';
part 'search_screen_query.dart';
part 'search_screen_scroll.dart';
part 'search_screen_search.dart';

enum _SearchMode { book, author }

/// The Search tab: a text field over either a pre-search "discover" grid
/// (search_screen_discover.dart) or live results (search_screen_search.dart),
/// with a Kitap/Ýazar mode toggle, genre chips and a full filter page
/// (search_screen_filter.dart) all narrowing the same query. Split across
/// the `part` files above as `extension`s on the private State class, the
/// same way [ReaderProvider] and the PDF/CBZ reader screens are.
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
  // Set once the filter page has actually been applied — [_filterSort]
  // starts equal to [kDefaultSortBy], the same value "Ýüklenen wagty
  // (täzeden köne)" carries, so equality alone can't tell "never touched"
  // apart from "the user picked that option on purpose". See
  // [_SearchScreenDiscover._discoverSort].
  bool _sortChosenByUser = false;

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
      : _hasQuery ||
          _selectedGenreId != null ||
          _filterLanguageIds.isNotEmpty ||
          _filterFormats.isNotEmpty ||
          _filterStartYear != null ||
          _filterEndYear != null;

  // Any active filter lights the red badge on the filter button. The genre
  // chips aren't in here on purpose: a selected one is already visibly
  // highlighted in the row right next to the button.
  bool get _hasActiveFilters => _filterActive;

  RangeValues get _filterYearRange => RangeValues(
        (_filterStartYear ?? kDefaultYearRange.start).toDouble(),
        (_filterEndYear ?? kDefaultYearRange.end).toDouble(),
      );

  @override
  Widget build(BuildContext context) => _buildScreen(context);

  /// `setState` is `@protected` on [State] — see [PdfReaderScreen]'s
  /// equivalent wrapper for why the `extension`s in the part files above
  /// need this instead of calling `setState(...)` directly.
  void _setState(VoidCallback fn) => setState(fn);
}
