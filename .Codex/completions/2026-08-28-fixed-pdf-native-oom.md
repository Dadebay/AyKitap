# Fixed PDF native OOM

## Problem

Opening book 426 terminated the Android process inside PDFium. The fixed-page
flow first opened the 17.2 MB PDF to classify it as text/image-only and then
opened the same file again in `PdfViewer`. The first, nonessential native
allocation exhausted the process before Dart could catch an exception.

## Change

- Fixed-page opening no longer invokes PDFium for classification.
- A prior reflow classification is read from disk without opening the PDF.
- An unclassified PDF uses image-safe continuous/fit-width defaults.
- Flutter's decoded image cache is released before the native PDF viewer opens.
- Added focused tests for cached and unknown classification behavior.

## Verification

- `flutter test test/modules/reader/pdf_book_opener_test.dart` — passed (3 tests).
- Targeted `flutter analyze` — no issues.
- No APK or device build was run.

