# Transparent search error artwork

- Removed the embedded square background from Search's 3D no-connection illustration.
- Added a genuine alpha-channel PNG and wired Search's error state to it.
- Kept the message and retry behavior unchanged.

## Verification

- `flutter test test/modules/search/search_error_state_test.dart`
- `flutter analyze lib/modules/search/widgets/search_error_state.dart test/modules/search/search_error_state_test.dart`
- `git diff --check`
