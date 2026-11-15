# iPad full-screen launch — 2026-11-10

## Cause and change

The iOS target and installed app already advertise both iPhone and iPad (`UIDeviceFamily = [1, 2]`). The Flutter startup path nevertheless called `AppOrientationPolicy.updateWindow` with a fake compact/phone-sized window before a real `MediaQuery` existed. On the iPad Air 11-inch (M4) iPadOS 27 simulator, that forced a portrait-only scene that appeared as a narrow, phone-width panel over the wallpaper.

Removed the speculative startup orientation update in `lib/main.dart`. `AppOrientationObserver` still applies the existing orientation policy when the actual scene dimensions arrive. No iOS device-family or `UIRequiresFullScreen` setting was changed.

## Verification

- Rebuilt and launched the app on the same iPad Air simulator. The Home screen filled the 1640 × 2360 simulator display instead of a roughly 820-pixel-wide centered panel.
- Terminated and relaunched the installed app; splash and Home still filled the display.
- `flutter test test/core/layout/app_orientation_policy_test.dart`: 9 tests passed, including compact-phone portrait and expanded-window cases.
- `flutter analyze lib/main.dart lib/core/layout/app_orientation_policy.dart lib/core/layout/app_orientation_observer.dart`: no issues.
- `git diff --check`: clean.

- A clean iPad Air 13-inch (M4) simulator opened the first-run onboarding and language picker across the entire 2048 × 2732 display. Selecting a language then opened a full-screen Home screen. Screenshots: `/tmp/aykitap_ipad_language_fixed.png` and `/tmp/aykitap_ipad_home_full.png`.
