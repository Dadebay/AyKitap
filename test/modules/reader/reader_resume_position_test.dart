// Regression tests for "an EPUB reopens a screen either side of where I left
// off". The cause was ordering, not arithmetic: the book was displayed at its
// saved CFI and *then* handed its font, and a typeface with different metrics
// repaginates the text underneath that CFI — so the CFI ended up resolving to
// the neighbouring screen. The font is now read before the viewer is built and
// travels to the WebView with the book (EpubViewer.initialFontBase64).
import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

EpubLocation _location({required double progress, required String cfi}) =>
    EpubLocation(
      startCfi: cfi,
      endCfi: cfi,
      href: 'ch1.xhtml',
      tocHref: 'ch1.xhtml',
      progress: progress,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StreakService.instance.resetForTest();
    FakeDioAdapter.install();
  });

  group('everything the viewer reads once is ready before it is built', () {
    test('isInitialized only flips once the saved state has been read',
        () async {
      final provider = ReaderProvider();
      // The viewer is gated on this: EpubViewer reads initialCfi, the font and
      // the display settings a single time, so building it before these have
      // been read off disk is a race on which side wins.
      expect(provider.isInitialized, isFalse);

      await provider.initialize(bookId: 1, bookTitle: 'Test');

      expect(provider.isInitialized, isTrue);
      addTearDown(provider.dispose);
    });

    test('the font is loaded by the time the viewer may be built', () async {
      final provider = ReaderProvider();
      await provider.initialize(bookId: 1, bookTitle: 'Test');
      addTearDown(provider.dispose);

      // This is the fix. The font used to be pushed into a rendition that had
      // already displayed at the saved CFI, repaginating it; now it is in hand
      // before the book is ever handed to the WebView.
      expect(provider.isInitialized, isTrue);
      expect(provider.readerFontBase64, isNotNull);
      expect(provider.readerFontBase64, isNotEmpty);
      expect(provider.readerFontCssName, isNotEmpty);
    });

    test('the saved position is read before the viewer may be built', () async {
      SharedPreferences.setMockInitialValues({
        'book_7_cfi': 'epubcfi(/6/14[ch3]!/4/2/10,/1:0,/1:40)',
        'book_7_progress': 0.42,
        'book_7_page': 96,
      });

      final provider = ReaderProvider();
      await provider.initialize(bookId: 7, bookTitle: 'Test');
      addTearDown(provider.dispose);

      expect(provider.savedCfi, 'epubcfi(/6/14[ch3]!/4/2/10,/1:0,/1:40)');
      expect(provider.isInitialized, isTrue);
    });
  });

  group('the opening position is not overwritten while it is being restored',
      () {
    test('a relocation mid-restore does not overwrite the saved CFI', () async {
      const savedCfi = 'epubcfi(/6/14[ch3]!/4/2/10,/1:0,/1:40)';
      SharedPreferences.setMockInitialValues({
        'book_9_cfi': savedCfi,
        'book_9_progress': 0.42,
      });

      final provider = ReaderProvider();
      await provider.initialize(bookId: 9, bookTitle: 'Test');
      addTearDown(provider.dispose);

      // What a reflow reports: the section's start rather than the exact page.
      // Letting this reach disk is what walked the position backwards a little
      // further on every reopen.
      provider.onRelocated(
          _location(progress: 0.31, cfi: 'epubcfi(/6/14[ch3]!/4/2/2,/1:0)'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('book_9_cfi'), savedCfi);
      expect(prefs.getDouble('book_9_progress'), 0.42);
    });

    test('a deliberate move disarms the guard, so the reader is saved',
        () async {
      SharedPreferences.setMockInitialValues({
        'book_11_cfi': 'epubcfi(/6/14[ch3]!/4/2/10,/1:0,/1:40)',
        'book_11_progress': 0.42,
      });

      final provider = ReaderProvider();
      await provider.initialize(bookId: 11, bookTitle: 'Test');
      addTearDown(provider.dispose);

      // The reader turned a page themselves before the restore check ran —
      // from here on their position is the authority, not the saved one.
      provider.cancelPositionRestore();
      const movedCfi = 'epubcfi(/6/16[ch4]!/4/2/6,/1:0)';
      provider.onRelocated(_location(progress: 0.55, cfi: movedCfi));
      await provider.saveAndClose();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('book_11_cfi'), movedCfi);
      expect(prefs.getDouble('book_11_progress'), 0.55);
    });
  });
}
