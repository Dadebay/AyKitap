import 'package:aykitap/core/localization/strings/library_strings.dart';
import 'package:aykitap/modules/library/library_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reading owns downloaded offline access without a separate tab', () {
    expect(LibraryScreen.tabCount, 5);
    expect(LibraryScreen.tabLabels, contains(LibraryStrings.tabReading));
    expect(
        LibraryScreen.tabLabels, isNot(contains(LibraryStrings.tabDownloaded)));
    expect(LibraryScreen.readingOpensLocalFilesWhenOffline, isTrue);
    expect(const LibraryScreen().initialTabIndex, 0);
    expect(() => LibraryScreen(initialTabIndex: 5), throwsAssertionError);
  });
}
