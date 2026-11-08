# Active subscription profile card

## Completed

- Replaced the generic active-subscription profile row with a dedicated
  Aýkitap Plus status card.
- Added separate light and dark gradients, foregrounds, translucent metric
  surfaces, borders, and shadows for reliable contrast in both themes.
- Shows active status, all-books-unlocked benefit, expiry date, remaining
  days, and a clear manage-subscription action.
- Added a subtle press-scale interaction while preserving the existing
  navigation and subscription business logic.
- Kept inactive subscriptions on the compact subscribe entry.
- Added Turkmen, Russian, Turkish, and English strings for all new content.

## Verification

- Changed Dart files are formatted.
- Targeted files pass `git diff --check`.
- Per user request, no Flutter build or APK build was run.

