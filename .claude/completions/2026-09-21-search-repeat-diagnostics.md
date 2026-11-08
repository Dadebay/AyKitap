# Search "the same books keep coming back" — diagnostics widened

Report (14.09.2026): *İçimizdeki çocuk, Beyaz leke, Гордые души, Veyl, Сила
уверенности в себе* keep reappearing. The Spy×Family manga series repeating is
**expected** (a series really does have many similarly-named volumes) — it is
watched only so it can be told apart from the rest.

## What was already there, and why it stayed silent
`logLookalikeResults` (yellow ⚠) was wired **only into the typed-search path**.
The reader's own words were "goni search page girenizde" — the **discover**
grid, shown before anything is typed, which had no diagnostics at all. So the
log's silence proved nothing.

## Changes
- `search_screen_discover.dart` — both diagnostics now run on the discover
  grid, over the **accumulated** list rather than the single page just
  fetched: a book that arrives again three pages down is exactly what a
  per-page check misses.
- `search_result_diagnostics.dart` — new `logWatchedTitleSightings` (cyan 👁)
  prints **position, id and page** for each of the reported titles.
  `watchedBookTitles` holds them as data; matching is a word-subset
  (`matchesWatchedTitle`), so `'spy family'` also catches `'Spy x Family,
  Vol. 3'`.
- `search_screen_search.dart` — the watched-title log added to typed search
  too, so the two paths can be compared.

## Why two logs
They answer different questions, and the reports look identical on screen:

| log | means |
|---|---|
| ⚠ `SAME ID` | the page genuinely carried one book twice — a backend fault |
| ⚠ `SAME TITLE` | different ids, indistinguishable titles — two editions/languages, or a catalogue duplicate |
| 👁 same id, **different pages** | arrives once per page as you scroll — a pagination fault |
| 👁 same id, **position #1-#6, every visit** | not a duplicate at all: it sits near the top of the day's sort order |

The last row is the one no amount of dedupe would fix, and (given a catalogue
scan that found 610 books / 610 unique ids) is the most likely answer.

## Tests
`test/modules/search/search_result_diagnostics_test.dart` — 4 new tests for
`matchesWatchedTitle`, including that no watched entry matches everything.

`flutter test`: 393 passed, 2 failed — both pre-existing in
`settings_screen_revenue_cat_test.dart`. `flutter analyze lib/ test/`: 0 errors.

---

## Verdict from the live log (21.09.2026, discover, pages 2→22, 644 books)

**The app is not duplicating anything.** Zero `SAME ID` warnings in 22 pages,
and every watched book kept a **fixed position** across every append —
`Beyaz Leke 1` at #48 from page 2 through page 22, `Içimizdeki çocuk` at #166,
`Гордые души` at #446. That is proof that pagination neither repeats nor
reshuffles rows.

### What the reader is actually seeing
1. **Series volumes sitting next to each other** — the largest part of it:
   - `Beyaz Leke 1: Mahkumiyet` #48 and `Beyaz leke 2 : Özgürlük` #50
   - `Spy × Family 1.1 … 1.6` at #290–#295, six in a row
   - `Veyl - Kötülerin Şehri 1` #342

   Near-identical titles and covers adjacent in a 3-column grid read as "the
   same book over and over". Not a fault.

2. **Four genuine catalogue duplicates** — one book uploaded twice under two
   ids. Backend data, nothing the app can be blamed for:

   | title | ids |
   |---|---|
   | Insancıklar | 250, 361 |
   | Karamazov Kardeşler | 598, 243 |
   | Mürebbiye | 248, 430 |
   | Я и деньги 2 | 373, 634 |

   Note the pattern: one of each pair carries a **trailing space**
   (`"Karamazov Kardeşler "`, `"Mürebbiye "`). The second upload was typed by
   hand, and the trailing space is likely what slipped past any uniqueness
   check. Same story in `"Içimizdeki çocuk "` (also spelled with Latin `I`
   rather than `İ`).

### Recommendation
Send the four id pairs to the backend developer to merge. No app-side dedupe:
there are no duplicate *ids* to drop, and hiding rows by title would risk
hiding two genuinely different books that share one.

### Also observed
The run paged straight through to the end of the catalogue (page 22, 644
books). That is the new load-more trigger working, but it may be chaining more
eagerly than intended — worth watching on the next run.
