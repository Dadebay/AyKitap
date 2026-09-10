// Behavior-preserving regression tests for [ReaderProvider], written before
// splitting the file (see docs/claude-provider-refactor-prompt.md, step B).
// Covers exactly the three areas the refactor plan calls out as highest-risk:
// dispose-time cleanup, app-lifecycle-driven streak flushing, and page
// progression/persistence — so a future split that accidentally drops one of
// these fails loudly instead of shipping a silent regression.
import 'package:aykitap/core/network/streak_endpoints.dart';
import 'package:aykitap/core/services/bookmarks_store.dart';
import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

EpubLocation _location({
  required double progress,
  required String cfi,
  int page = 0,
  int totalPages = 0,
  String href = 'ch1.xhtml',
}) =>
    EpubLocation(
      startCfi: cfi,
      endCfi: cfi,
      href: href,
      tocHref: href,
      progress: progress,
      page: page,
      totalPages: totalPages,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StreakService.instance.resetForTest();
  });

  group('lifecycle observer wiring', () {
    test('dispose removes the WidgetsBindingObserver it registered', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 1, bookTitle: 'Test');

      await provider.saveAndClose();
      provider.dispose();

      // If dispose actually deregistered, WidgetsBinding no longer knows
      // this instance — removing an observer that isn't registered returns
      // false instead of true.
      expect(WidgetsBinding.instance.removeObserver(provider), isFalse);
    });

    test(
        're-initializing without disposing does not register a duplicate observer',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 1, bookTitle: 'First');
      await provider.initialize(bookId: 2, bookTitle: 'Second');

      await provider.saveAndClose();
      provider.dispose();

      // A duplicate registration would leave one copy behind after dispose's
      // single removeObserver call — this second, manual removal would then
      // still find (and remove) it, returning true instead of false.
      expect(WidgetsBinding.instance.removeObserver(provider), isFalse);
    });
  });

  group('app lifecycle → streak ping', () {
    test(
        'pause/resume transitions never throw and never crash a disposed provider',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 3, bookTitle: 'Test');

      expect(
          () => provider.didChangeAppLifecycleState(AppLifecycleState.paused),
          returnsNormally);
      expect(
          () => provider.didChangeAppLifecycleState(AppLifecycleState.resumed),
          returnsNormally);
      expect(
          () => provider.didChangeAppLifecycleState(AppLifecycleState.inactive),
          returnsNormally);

      await provider.saveAndClose();
      provider.dispose();
    });

    test(
        'saveAndClose followed by dispose reports the streak residual exactly once',
        () async {
      final adapter = FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 4, bookTitle: 'Test');

      // Let real elapsed time accrue on the streak stopwatch so the flush
      // below has a non-zero residual to actually send.
      await Future<void>.delayed(const Duration(seconds: 1));

      await provider.saveAndClose();
      // dispose() flushes again as a safety net for exit paths that skip
      // saveAndClose — the residual must already be zeroed out by then, or
      // this would double-report the same seconds (the exact bug the
      // Stopwatch reset in _flushStreakResidual guards against).
      provider.dispose();

      // Both flushes are fire-and-forget (dispose() can't be async), so give
      // their network calls a moment to actually reach the fake adapter
      // before counting them.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final streakRequests =
          adapter.requests.where((r) => r.path == StreakEndpoints.streakReport);
      expect(streakRequests.length, 1);
    });
  });

  group('page progression', () {
    test('onRelocated updates page/progress state synchronously', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 5, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.5, cfi: 'epubcfi(/6/4)', page: 10, totalPages: 20));

      expect(provider.currentPage, 10);
      expect(provider.totalPages, 20);
      expect(provider.progress, 0.5);
      expect(provider.currentCfi, 'epubcfi(/6/4)');
      expect(provider.isAtLastPage, isFalse);

      await provider.saveAndClose();
      provider.dispose();
    });

    test('progress persists locally only after the 2s debounce settles',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 6, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.25, cfi: 'epubcfi(/6/2)', page: 3, totalPages: 12));

      final prefsBeforeDebounce = await SharedPreferences.getInstance();
      expect(prefsBeforeDebounce.getInt('book_6_page'), isNull);

      await Future<void>.delayed(const Duration(seconds: 3));

      final prefsAfterDebounce = await SharedPreferences.getInstance();
      expect(prefsAfterDebounce.getInt('book_6_page'), 3);
      expect(prefsAfterDebounce.getDouble('book_6_progress'), 0.25);
      expect(prefsAfterDebounce.getString('book_6_cfi'), 'epubcfi(/6/2)');

      provider.dispose();
    });

    test('a pending debounced save still flushes when the app is backgrounded',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 21, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.4, cfi: 'epubcfi(/6/6)', page: 5, totalPages: 12));
      // Swiping the app away right after a page turn — well inside the 2s
      // debounce. The pending timer cannot be relied on here: a suspended
      // process can be killed before it ever fires, which is what used to
      // lose the last pages of every session.
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('book_21_page'), 5);
      expect(prefs.getDouble('book_21_progress'), 0.4);
      expect(prefs.getString('book_21_cfi'), 'epubcfi(/6/6)');

      provider.dispose();
    });

    test('the position saved on background is what the book reopens at',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 22, bookTitle: 'Test');
      provider.onRelocated(_location(
          progress: 0.6, cfi: 'epubcfi(/6/14)', page: 8, totalPages: 12));
      provider.didChangeAppLifecycleState(AppLifecycleState.detached);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      provider.dispose();

      // A fresh reader for the same book — what happens after the app is
      // killed and relaunched. savedCfi is what EpubViewer opens at.
      final reopened = ReaderProvider();
      await reopened.initialize(bookId: 22, bookTitle: 'Test');

      expect(reopened.savedCfi, 'epubcfi(/6/14)');
      expect(reopened.currentPage, 8);
      expect(reopened.progress, 0.6);

      reopened.dispose();
    });

    test('a pending debounced save still flushes on saveAndClose', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 7, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.75, cfi: 'epubcfi(/6/8)', page: 9, totalPages: 12));
      // Close immediately — well inside the 2s debounce window — mirroring a
      // reader that's closed right after a page turn.
      await provider.saveAndClose();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('book_7_page'), 9);
      expect(prefs.getDouble('book_7_progress'), 0.75);

      provider.dispose();
    });
  });

  group('reopening at the saved position', () {
    // The reported regression: left off at 11% of the book, came back to 4%,
    // and each reopen slipped a little further. Applying the saved font
    // size/theme/spread in onEpubLoaded reflows the book, and epub.js can
    // report the current *section's* start instead of the page it opened at
    // — which then got saved over the good position.
    test('a relocation reported mid-restore never overwrites the saved spot',
        () async {
      FakeDioAdapter.install();
      SharedPreferences.setMockInitialValues({
        'book_31_progress': 0.5,
        'book_31_page': 40,
        'book_31_cfi': 'epubcfi(/6/20)',
      });
      final provider = ReaderProvider();
      await provider.initialize(bookId: 31, bookTitle: 'Test');

      // The reflow reports the section start rather than the saved page.
      provider.onRelocated(_location(
          progress: 0.1, cfi: 'epubcfi(/6/4)', page: 8, totalPages: 80));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('book_31_cfi'), 'epubcfi(/6/20)');
      expect(prefs.getDouble('book_31_progress'), 0.5);

      provider.dispose();
    });

    test('the guard is not armed for a book with no saved position', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 32, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.2, cfi: 'epubcfi(/6/6)', page: 4, totalPages: 20));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('book_32_progress'), 0.2);
      expect(prefs.getString('book_32_cfi'), 'epubcfi(/6/6)');

      provider.dispose();
    });

    test('the reader navigating themselves drops the guard and saves again',
        () async {
      FakeDioAdapter.install();
      SharedPreferences.setMockInitialValues({
        'book_33_progress': 0.5,
        'book_33_page': 40,
        'book_33_cfi': 'epubcfi(/6/20)',
      });
      final provider = ReaderProvider();
      await provider.initialize(bookId: 33, bookTitle: 'Test');

      // What nextPage/prevPage/goToChapter/a scrubber seek all do first.
      provider.cancelPositionRestore();
      provider.onRelocated(_location(
          progress: 0.62, cfi: 'epubcfi(/6/30)', page: 50, totalPages: 80));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('book_33_cfi'), 'epubcfi(/6/30)');
      expect(prefs.getDouble('book_33_progress'), 0.62);

      provider.dispose();
    });

    test('a book that fails to load releases the guard', () async {
      FakeDioAdapter.install();
      SharedPreferences.setMockInitialValues({
        'book_34_progress': 0.5,
        'book_34_cfi': 'epubcfi(/6/20)',
      });
      final provider = ReaderProvider();
      await provider.initialize(bookId: 34, bookTitle: 'Test');

      provider.onEpubLoadFailed();
      provider.onRelocated(_location(
          progress: 0.55, cfi: 'epubcfi(/6/22)', page: 44, totalPages: 80));
      provider.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('book_34_cfi'), 'epubcfi(/6/22)');

      provider.dispose();
    });
  });

  group('bookmarks', () {
    test('toggleBookmark adds then removes a mark at the current position',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 8, bookTitle: 'Bookmark test');
      provider.onRelocated(_location(
          progress: 0.1, cfi: 'epubcfi(/6/1)', page: 1, totalPages: 10));

      expect(provider.isCurrentPageBookmarked, isFalse);

      final added = await provider.toggleBookmark();
      expect(added, isTrue);
      expect(provider.isCurrentPageBookmarked, isTrue);
      expect(BookmarksStore.instance.forBook(8), hasLength(1));

      final addedAgain = await provider.toggleBookmark();
      expect(addedAgain, isFalse);
      expect(provider.isCurrentPageBookmarked, isFalse);
      expect(BookmarksStore.instance.forBook(8), isEmpty);

      await provider.saveAndClose();
      provider.dispose();
    });
  });
}
