# Quick start

Read the root [README](../README.md) for setup, signing, distribution, and store links.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

The first PDF-related test or Android build may download PDFium. Keep credentials and signing files outside Git. Follow the PR checks before merging to `main`.
