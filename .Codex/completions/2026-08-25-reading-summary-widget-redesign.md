# Reading summary widget redesign

## Completed

- Redesigned the Android 3x2 widget around the real last-read book cover,
  title, page position, and reading progress.
- Added live current-streak and today's-pages counters.
- Added a seven-day goal row with completed, current, and empty day states.
- Added attractive sample content to the Android launcher picker preview.
- Added the same book/streak/today/week data to the iOS widget.
- Changed widget links to `aykitap://reader/<bookId>`.
- Added reader deep-link handling: opens the downloaded last-read book directly
  when access is valid, otherwise falls back to its catalogue detail page.
- Connected today's page and weekly streak data to successful reading reports.

## Verification

- Android widget XML and drawable resources parse successfully.
- Targeted changed files pass `git diff --check`.
- Per user request, no Flutter build, APK build, or device installation was run.

