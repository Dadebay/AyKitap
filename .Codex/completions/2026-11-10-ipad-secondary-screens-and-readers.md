# iPad secondary screens and reader layout

## Completed

- Capped the notification permission dialog and book-detail description/read actions at readable tablet widths; enlarged related-book cards and detail text.
- Resized library, search, profile, author, network, reader, and balance empty/error states for tablet screens. Kept their text and primary actions within a centered content column.
- Sized search controls, book and author grids, genre results, and the filter screen for iPad. Search grid cover heights now use the actual available width.
- Centered profile pages, streak and subscription pages, TMCELL payment, request bar, and profile/payment/reader bottom sheets within tablet widths. Increased profile entry, header, and shared reader setting control sizes.
- Centered EPUB pages in a 720-point viewport and PDF/CBZ pages in an 860-point viewport. Kept the reader chrome over the page so opening controls does not resize the reading area. Bounded CBZ image decode width to limit memory use on larger displays.

## Verification

- Targeted `flutter analyze` on modified modules: no issues.
- Full `flutter analyze --no-fatal-infos`: no errors in modified modules; unrelated existing warnings remain in `device_fingerprint.dart`, `firebase_auth_client.dart`, and vendored `flutter_pdfview` tests.
- Existing search, profile and reader widget tests: 17 passed.
- `git diff --check`: clean.
- Device visual verification left to the user as requested.
