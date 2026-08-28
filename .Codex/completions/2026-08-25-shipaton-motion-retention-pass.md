# Shipaton motion and retention pass

## Scope

The onboarding goal / 10 TMT explanation, foldable work and widget validation
were explicitly removed from this pass.

## Completed

- Verified the existing catalogue detail → reader cover Hero and reduced-motion
  fallback across EPUB, PDF and CBZ entry paths.
- Added one-shot Home section stagger on successful data load.
- Added press feedback to series and ranked-book cards using the shared motion
  tokens.
- Changed the week streak effect so existing completed days do not replay;
  only a new false → true goal transition animates with three small particles.
- Added a non-blocking daily-goal completion overlay.
- Replaced full-screen subscription confetti with a focused one-shot unlock
  state that can be reused by RevenueCat later.
- Added an offline Home status banner and a one-shot restored state; reconnect
  refreshes Home data without clearing usable cached shelves.
- Added `reader_opened`, `paywall_viewed`, purchase lifecycle and
  `reading_goal_completed` analytics events. RevenueCat cancellation and
  restore events remain coupled to the future RevenueCat integration.
- Added reduced-motion and finite-animation widget tests.

## Verification

- Targeted `flutter analyze`: no issues found.
- `flutter test test/core/widgets/motion_effects_test.dart`: 4 tests passed.
- `git diff --check`: passed.
- No APK or application build was run, per user request.
