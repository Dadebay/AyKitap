# Search: the Awtor tab scrolls on instead of stopping at its first page

Reported as "the author tab shows about 20 authors — it would be nicer if it
looked unlimited".

## Cause

The book side of Search has always paged; the author side never did.

1. `_loadDiscoverAuthors` fetched exactly one page and had no `page`/
   `hasMore`/`loadingMore` state at all, so the grid was whatever that one
   request returned.
2. `_onResultsScroll` reached the bottom and called `_loadDiscoverBooks(loadMore: true)`
   **regardless of mode** — so scrolling the author tab paged the invisible
   book grid, and the authors on screen never grew.
3. `_runSearch` bailed out early for author mode (`if (loadMore && _searchMode
   == _SearchMode.author) return;`), so typed author searches were capped the
   same way.

## Fix

Author mode now pages exactly like book mode, in both of its grids:

- **Discover grid** (`_loadDiscoverAuthors`) gained `loadMore`, plus
  `_discoverAuthorsPage` / `_discoverAuthorsHasMore` /
  `_discoverAuthorsLoadingMore` alongside the book equivalents.
- **Typed search** (`_runSearch`) pages `GET /authors/search` through the
  existing `_searchPage`/`_searchHasMore`/`_searchLoadingMore` counters — the
  two modes are mutually exclusive and a mode switch re-runs from page 1, so
  one set of counters covers both.
- `_onResultsScroll` now routes the discover load-more by mode.
- `AuthorResultGrid` became a `CustomScrollView` + `SliverGrid` with a
  next-page spinner sliver, mirroring `SearchResultGrid`.

### Why "has more" counts new ids rather than page length

`mergeAuthorPage` (new, `lib/modules/search/author_page_merge.dart`) appends a
page while dropping ids already on screen, and returns how many were new.
`hasMore` is `added > 0`.

The obvious check — "did this page come back as long as the `size` I asked
for?" — is what the book grid uses, but it misreads this endpoint. The tab
requests `size: 30` and the user was seeing ~20, so the endpoint returns fewer
rows than asked for; a length check would call that the last page on the very
first request and pagination would never start. Counting new ids also protects
the other direction: a backend that ignored `page` would return the same rows
forever, and a length check would append them endlessly.

## Changed files

- `lib/modules/search/author_page_merge.dart` (new)
- `lib/modules/search/search_screen.dart` — author paging state
- `lib/modules/search/search_screen_discover.dart` — `loadMore` support
- `lib/modules/search/search_screen_search.dart` — author-mode paging
- `lib/modules/search/search_screen_scroll.dart` — route load-more by mode
- `lib/modules/search/search_screen_body.dart` — pass `loadingMore` through
- `lib/modules/search/widgets/author_result_grid.dart` — sliver grid + spinner
- `test/modules/search/author_page_merge_test.dart` (new, 7 tests)

## Verification

- `flutter test test/modules/search/` — 7/7 pass, covering both backend
  behaviours above (a short page keeps scrolling; a repeated page stops it).
- `flutter analyze lib/modules/search test/modules/search` — no new issues
  (2 pre-existing style infos remain).
- `flutter test` — 285 pass, 2 fail; both are the long-standing
  `settings_screen_revenue_cat_test.dart` failures from the in-progress
  RevenueCat/IAP work, unrelated to Search.

## Worth checking on a device

Open Search → Awtor and scroll: more authors should keep arriving with a
spinner between pages, and the same author should never appear twice. Typing a
name and scrolling those results should behave the same.

If the grid still stops at ~20, that means the backend genuinely has only that
many authors — the client now asks for page 2 either way, so the next place to
look would be the `GET /authors/search` response for `page=2`.
