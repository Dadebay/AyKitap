# Search screen: default "discover" grid before a search

**Date**: 2026-08-03
**Files**: `lib/modules/search/search_screen.dart`, `lib/core/services/book_api_service.dart`

## What changed

Below the tab bar/chips row on `SearchScreen`, the area that used to render
nothing until `_shouldShowResults` was true now shows a grid of books even
before the user types or picks a filter — `GET /books/all?sort_by=created_at&sort_order=DESC&size=30`,
fetched once in `initState` alongside the genre chips.

## Why `created_at DESC`, not random

Backend dev's call: true random ordering has no stable sort underneath it, so
the same page boundary can't be reproduced across `page`/`size` requests and
pagination breaks. `sort_by`/`sort_order` are real `GET /books/all` params
(confirmed against the Postman collection — `created_at`/`name`/`year` ×
`ASC`/`DESC`), so recently-added-first stands in for a random default feed
without touching pagination.

`BookApiService.listBooks` gained `sortBy`/`sortOrder` (threaded through
`_listBooksByLanguages` too) — no existing caller passes them, so this is
additive.

## Notes / follow-ups not in scope here

- The discover grid doesn't refetch on language switch the way
  `HomeDataService` now does (see `2026-08-03-accept-language-header.md`) —
  same staleness gap, not addressed on this pass.
- Toggling a genre chip off / clearing the query brings the discover grid
  back (previously that area just went blank) — this is the intended
  behavior per the request, not a side effect to guard against.
