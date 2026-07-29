# Quick Start

## Run
flutter run
flutter run -d chrome   # web test

## Build
flutter build apk --release
flutter build ios --release
flutter build ipa

## Dependencies
flutter pub get
flutter pub upgrade
flutter clean && flutter pub get

## Code Quality
dart fix --apply
flutter analyze
flutter test

## Useful
flutter pub deps        # bağımlılık ağacı
flutter doctor          # ortam kontrolü
