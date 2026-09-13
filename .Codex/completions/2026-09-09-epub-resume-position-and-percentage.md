# EPUB: reopening at the right place, and a progress figure that holds still

Reported as "it doesn't resume where I left off — I was on 17/153, came back
to 6/131, and the total page count shrank too".

Those are two separate problems wearing one coat, and the page-count detail is
what separates them. `page` and `totalPages` are both derived by dividing a
location index by the same `perPage` divisor (`epubView.js` `pageInfoFor`), so
the *ratio* cancels the divisor out: 17/153 = 11%, 6/131 = 4.6%. The ratio
moved, so the reading position genuinely moved — the shrinking total is a
second, cosmetic issue on top.

## 1. The position really was slipping backwards (the bug)

**Cause.** `onEpubLoaded` applies the saved page transition, font, font size,
theme and spread immediately after the book opens at its saved CFI. Each of
those reflows the book, and epub.js's re-layout can redisplay the current
*section's* start instead of the exact page — the same failure mode already
documented on `resizeToAvoidBottomInset: false` in `reader_view_body.dart`.

That knocked-back position then arrived as a normal `relocated` event, which
scheduled the usual debounced save and wrote itself over the good one. So the
damage compounded: every reopen started a little earlier than the last, and
the previous session's background-flush fix made it land more reliably.

**Fix.** A guard around the opening window, in `ReaderProvider`:

- `_restoringPosition` is armed in `initialize` whenever the book has a saved
  CFI and progress. While armed, relocations still drive the UI but are **not
  persisted** — neither the 2-second debounce nor the background flush. The
  copy on disk is the trustworthy one until the book has actually reached it.
- `_verifyRestoredPosition` runs once, `_restoreSettleDelay` (900 ms) after the
  rendition is configured. If the book came to rest *behind* the saved
  position by more than `_restoreDriftTolerance`, it re-asserts the saved CFI.
  It only ever corrects backwards drift, so a reader who has already moved on
  is never dragged back.
- Any deliberate navigation drops the guard first
  (`cancelPositionRestore`, called from `nextPage`/`prevPage`/`goToChapter`/
  `goToCfi`/the new `seekToProgress`), so the reader's own move is saved
  normally instead of being mistaken for drift.

Two release paths keep the guard from ever sticking (a stuck guard would mean
a session that never saves at all): it is armed *before* the appearance calls
that can throw over the WebView bridge, and `onEpubLoadFailed` clears it.

## 2. The page numbers were never stable to begin with (the cosmetic half)

Reflowable text has no inherent pages. `pageInfoFor` measures how many
locations fit on the current screen, averages the first few text screens, then
freezes that as the divisor. It is font-, orientation- and sample-dependent, so
the same spot in the same book legitimately reads 17/153 one session and
14/131 the next even when the position is perfect.

The percentage does not have this problem: it comes from `location.start.percentage`
over `book.locations`, generated deterministically at `generate(1600)` and
cached across opens.

So the EPUB reader now shows the percentage instead of a page count — both in
the bottom bar's scrubber (`ReaderProgressScrubber.showPercentage`, new) and in
the focus-mode label. **PDF and CBZ keep their page numbers**: those pages are
real and fixed, and the scrubber is shared, so the new flag is opt-in.

## Changed files

- `lib/modules/reader/provider/reader_provider.dart` — guard state + constants
- `lib/modules/reader/provider/reader_provider_lifecycle.dart` — arm in
  `initialize`, respect it in the background flush, release on load failure
- `lib/modules/reader/provider/reader_provider_callbacks.dart` —
  `_verifyRestoredPosition`, `cancelPositionRestore`, suppressed save
- `lib/modules/reader/provider/reader_provider_ui_actions.dart` — navigation
  drops the guard; new `seekToProgress`
- `lib/modules/reader/provider/reader_provider_persistence.dart` — reset
- `lib/modules/reader/widgets/reader_progress_scrubber.dart` — `showPercentage`
- `lib/modules/reader/widgets/reader_bottom_bar.dart` — EPUB opts in
- `lib/modules/reader/views/reader_view_epub_viewer.dart` — focus-mode label
- `lib/modules/reader/views/reader_view_chrome.dart` — seek via the provider
- `test/modules/reader/reader_provider_lifecycle_test.dart` — +4 tests

`packages/sakura_epub` untouched again — no change to the vendored JS.

## Verification

- `flutter test test/modules/reader/` — 59/59 pass.
- The central new test ("a relocation reported mid-restore never overwrites the
  saved spot") was confirmed to **fail** with the guard disarmed, so it pins
  the real bug.
- `flutter analyze lib/modules/reader test/modules/reader` — no new issues.
- `flutter test` — 271 pass, 2 fail; both are the same pre-existing
  `settings_screen_revenue_cat_test.dart` failures from the in-progress
  RevenueCat/IAP work, confirmed earlier to fail identically with all reader
  changes stashed.

## Worth checking on a device

Read a way into an EPUB, force-quit, reopen: it should come back to the same
percentage, and stay there across several open/close cycles rather than
creeping backwards. The bottom bar and focus label should read e.g. "%11"
instead of "17 / 153"; PDF and CBZ should still show real page numbers.
