# Align daily reading goal with 15-minute streak

## Changes

- Raised the device-local daily reading goal from 10 to 15 minutes. The home card derives its denominator and progress fill from this target.
- Updated home and onboarding reading-duration copy in all four app languages to 15 minutes. The separate 10 TMT reward amount is unchanged.
- Kept streak/reward reporting server-driven. Its app-side default and API model fallback were already 15 minutes.
- Updated the focused service test to prove that 10 minutes is incomplete and 15 minutes completes the local goal.

## Verification

- `flutter test --no-pub test/core/services/daily_reading_goal_service_test.dart test/core/services/streak_service_test.dart test/modules/home/home_screen_rebuild_test.dart`: 9 passed.
- Targeted `flutter analyze --no-pub --no-fatal-infos`: no issues.
- Search found no remaining user-facing 10-minute streak copy in app sources.
- Android APK built, but the connected phone disconnected from ADB during install, so the new home screen was not visually checked on-device.
