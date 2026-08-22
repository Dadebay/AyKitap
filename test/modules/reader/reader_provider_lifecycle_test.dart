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
