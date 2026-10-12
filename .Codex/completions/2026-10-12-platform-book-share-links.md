# Platform-specific book share links

- Book shares now include the App Store link on iOS and Google Play link on Android.
- iOS uses text-only sharing to avoid the cached WebP attachment failure.
- Android retains its working cover-image share and gains the Play link.
- Added a popover origin for iPad compatibility and a localized failure message.

## Verification

- `flutter test test/core/constants/app_store_links_test.dart`
- `flutter analyze` on the changed share files
- `git diff --check`
