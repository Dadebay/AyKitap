# Architecture map

- `lib/main.dart`: app bootstrap and Provider registration.
- `lib/core/network/`: API base URL, Dio client, endpoints, and errors.
- `lib/core/services/`: authentication, purchases, reading, downloads, notifications, and account state.
- `lib/core/models/`: API and domain models.
- `lib/core/localization/`: Turkmen, Russian, and Turkish strings and locale state.
- `lib/modules/`: feature screens and widgets for auth, catalog, reader, library, payments, profile, and search.
- `packages/sakura_epub/`: vendored EPUB renderer. PDF uses the `pdfrx` dependency.
- `test/`: unit and widget tests, with `test/support/` transport and platform fakes.
- `android/` and `ios/`: native projects. Android release signing reads ignored `android/key.properties`.

Check the owning feature's tests before refactoring a screen or service. Keep UI, service, and network responsibilities in their current layers.
