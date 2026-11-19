# Reader features and verification — 2026-11-19

## Changes

- Kept the existing book-opening Lottie visible in EPUB, PDF, and CBZ, including the forced low-memory path. Low-memory mode uses a smaller animation at 15 fps; the system reduced-motion setting still uses a static icon.
- Added EPUB text-selection Dict routing: Google Translate app first, then the Google Translate link in Chrome, then the device's default browser if Chrome is unavailable.
- Added EPUB pinch-to-reflow font zoom, volume-key page turns in all three readers (volume down = next; up = previous), and automatic/manual reading brightness with a left-edge long-press control.
- Added a locally stored 10-minute reading goal and follow-up book offer without backend or admin-panel changes. Placed the compact goal card below the home banner with extra top space and an animated progress bar.
- Improved low-memory loading/caching and cleared stale screenshot protection at startup.
- Verified existing "Okuduklarym" shelf recency ordering on device: after returning from PDF and CBZ, the last opened book moved to the first slot. No library code change was needed.

## Verification

- `flutter test --no-pub test/modules/reader test/modules/home/home_screen_rebuild_test.dart test/core/services/daily_reading_goal_service_test.dart`: 115 passed.
- `flutter test --no-pub --dart-define=LOW_END=true test/modules/reader/reader_opening_lottie_test.dart`: 2 passed.
- Targeted `flutter analyze --no-pub --no-fatal-infos`: no errors or warnings; existing deprecation/info messages only.
- Android SM-A346E: built and ran with `LOW_END=true`; verified home goal card, DICT opening Chrome and Google Translate web page, EPUB/PDF/CBZ volume direction, and shelf recency ordering.
- Reinstalled and left the connected phone running with `LOW_END=false` so the existing blurred cover backdrop and other full-quality effects remain visible during normal use.
- This connected phone has about 5.3 GB RAM, so a physical 2 GB device remains untested. Google Translate app is not installed on this phone, so the native app branch is covered by code/unit test, while the Chrome fallback was exercised on device.

## Recovery

- Pre-work backup: `codex/reader-backup-20261119` at `b19c3fb` (pushed).
