# Merge Downloaded into Reading

- Removed the separate Downloaded tab from My Bookshelf.
- Kept locally opened books on Reading and retained its direct offline-file opening path.
- Changed the offline library shortcut to open My Bookshelf on Reading.
- Reduced the library tab controller and index bounds from six tabs to five.

## Verification

- `flutter test test/modules/library/library_screen_merged_reading_test.dart test/modules/library/api_books_tab_reading_sync_test.dart`
- `flutter analyze` on the changed library and navigation files
- `git diff --check`
