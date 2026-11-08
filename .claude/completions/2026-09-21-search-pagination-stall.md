# Search pagination stalled at the bottom

Report: *"alta varinca yeni kitaplar eklenmiyor, yukari gidip geri gelmek
lazim"* — reaching the end of the grid added nothing; scrolling up and back
down did.

## Cause
The load-more check lived **entirely inside** `_onResultsScroll`, i.e. it only
ever ran while a `ScrollNotification` was being dispatched. Two moments that
need it produce no such notification:

1. **A page landing while the reader rests at the bottom.** Appending rows
   changes the scroll *metrics*, which dispatches a `ScrollMetricsNotification`
   — **not** a `ScrollNotification`, so `NotificationListener<ScrollNotification>`
   never sees it. Nothing re-checked. Scrolling up and back down was the
   reader manually generating the notification the grid was waiting for.
2. **A first page too short to fill the screen.** Nothing can be scrolled, so
   no notification is ever produced and the grid stays at one page.

`test/modules/search/search_load_more_trigger_test.dart` proves both: the grid
doubles in height with **zero** scroll notifications.

## Fix
- The trigger now reads a live `ScrollController` (`_maybeLoadMore`) instead of
  a notification's metrics, so it can run outside a scroll.
- `_scheduleLoadMoreCheck()` re-runs it in a post-frame callback after **every**
  completed load (search, discover books, discover authors) — after the frame,
  so it reads the grown `maxScrollExtent`.
- Two controllers, one per grid *kind*: book and author grids are different
  widget types, so switching modes mounts the new scroll view before the old
  unmounts, and one shared controller would briefly be attached to two
  positions (an assertion). Within a kind the element is reused.

No loop risk: the load calls already no-op while one is in flight or when
`hasMore` is false, and each append pushes the bottom further away.

`flutter test`: 402 passed, 2 failed — both pre-existing in
`settings_screen_revenue_cat_test.dart`. `flutter analyze lib/ test/`: 0 errors.
