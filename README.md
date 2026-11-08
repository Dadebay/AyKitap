# Aýkitap

Aýkitap is a Flutter reading app for Turkmen and world literature. Readers can discover books, buy a title or subscribe, and read EPUB, PDF, and CBZ files. Downloaded books and imported personal files can be read offline. The app supports Turkmen, Russian, and Turkish.

## Get the app

- [Google Play](https://play.google.com/store/apps/details?id=com.aykitap.aykitap) — Android package `com.aykitap.aykitap`.
- [App Store](https://apps.apple.com/de/app/a%C3%BDkitap/id6791177731) — iOS bundle `com.aykitap.aykitap`.
- [Official website](https://aykitap.com.tm/tm).
- [GitHub Releases](https://github.com/Dadebay/AyKitap/releases) — source and verified direct-download artifacts, when a release is published. Use the stores until a signed APK appears here.

Store versions may differ from the source version in this repository. A GitHub release is not automatically an App Store or Google Play rollout.

## Development

Use the Flutter version pinned in CI (Flutter 3.47.8) with Dart 3.13 or a compatible newer stable version. Android builds use JDK 17. iOS builds require macOS, Xcode, and CocoaPods.

```bash
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

The PDF reader uses `pdfrx`. Its PDFium native asset is downloaded during the first build or test; network access to the upstream release is needed unless the tool cache already contains that asset. A download failure is a build-infrastructure failure, not a passing test.

### Architecture

- `lib/core/` contains network access, models, localization, services, shared widgets, and theme.
- `lib/modules/` contains screens and their feature-specific widgets and state.
- `packages/sakura_epub/` is the vendored EPUB reader. PDF rendering and reflow use `pdfrx`; the older `flutter_pdfview` fork is no longer used.
- `test/` contains unit and widget tests. Keep new behavior covered at the narrowest useful level.

`DioClient` sends API requests to `https://aykitap.com.tm/api/v1`. A fallback origin can be supplied at build time with `--dart-define=API_FALLBACK_BASE_URL=...`. Do not put private origins or credentials in Git. App language is sent in the `Accept-Language` header.

### Release signing

The Android release build requires a local `android/key.properties` file. It is ignored by Git. Example structure (replace placeholders locally; never commit real values):

```properties
storeFile=/absolute/path/to/your-release-key.jks
storePassword=YOUR_LOCAL_SECRET
keyAlias=YOUR_ALIAS
keyPassword=YOUR_LOCAL_SECRET
```

```bash
flutter build appbundle --release
flutter build apk --release
```

Release builds deliberately do not fall back to a debug key. Before publishing an APK, verify its package ID, version, certificate fingerprint, and SHA-256, and test it on an Android device. For updates over a Play-installed app, the APK certificate must match Google Play's **app signing certificate**; the upload certificate alone is insufficient.

For iOS, build and archive in Xcode with the correct team and provisioning profile. GitHub does not provide a general installable iOS binary; use the App Store or TestFlight.

## Review and release workflow

Apply the shared local Flutter project completion checklist. Work on a branch, use focused Conventional Commits, open a PR explaining changes and tests, and wait for green CI and review before merging to `main`. Tag the exact validated commit for a GitHub Release. Never attach an APK built from a different commit, or publish a debug-signed APK.

The repository's previous Turkmen README is kept at [docs/README-legacy-tk.md](docs/README-legacy-tk.md) for historical implementation notes. It predates the current version, tests, and PDF engine; use this README and current source code for build instructions.

See [release readiness](docs/release-readiness.md) for the remaining signing, privacy, account deletion, and device checks before a new store submission.

## License

No open-source license has been assigned. Source visibility does not grant redistribution rights.
