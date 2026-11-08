# Book detail transition performance

## Completed

- Deferred the blurred detail backdrop until the Hero route completes.
- Kept loading/error layout stable during the Hero flight.
- Moved favorite and access refreshes off the transition critical path.
- Removed the global 650px image decode floor and scoped it to Hero covers.
- Added `docs/book-detail-performance.md` with findings and device checks.

## Verification

- Relevant Flutter analyze run completed without errors.
- 14 Hero, press feedback, Home card and Library tests passed.
- `git diff --check` passed.
