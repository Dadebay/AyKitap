# "I bought one book, Purchased tab shows another" — purple diagnostics

Report: a book was bought, but **My Bookshelf → Satyn alnanlar** lists a
different one. No fix yet — this adds the logging that says *which* of three
different faults it is, because they need different fixes.

## The three candidates
1. **The wrong id was bought.** The purchase screen sent an id that isn't the
   book whose cover was tapped.
   → `💜 BUY sending — id=… "…"` / `BUY server accepted` in
   `book_purchase_screen.dart`, around `POST /users/buy-book/:id`.
2. **The backend's list is wrong.** `GET /books/all?bought=true` answers with
   a book that was never bought.
   → `💜 PURCHASED shelf — … returned N book(s)` plus one line per row, in
   `api_books_tab_actions.dart`'s `_load` (only on the tab that sets
   `syncsPurchasedAccess`).
3. **The grid renders the wrong cover.** Server and cache both right, the row
   on screen wrong. Only visible by comparing the printed rows (each with its
   position `#n`) against what the tab displays.

## Cache comparison
`logPurchasedShelf` reads `BookAccessService.purchasedIds` **before**
`replacePurchased` overwrites it — otherwise the two would always agree and
the comparison would say nothing. It then prints:

- `on server, not in local cache` — normal right after a purchase (the book
  just bought). Anything else is a book the backend thinks was bought and the
  app never saw.
- `in local cache, not on server` — a purchase that never registered, or a
  stale cache left from another account.

New file: `lib/modules/library/purchase_diagnostics.dart`. Debug builds only.

`flutter test`: 402 passed, 2 failed (pre-existing revenue-cat).
`flutter analyze`: clean.
