// Regression tests for the progress-notifier split introduced to stop a page
// relocation from rebuilding the whole reader screen (see
// reader_provider_callbacks.dart's `onRelocated`/`_updateProgressSnapshot`
// and reader_view_chrome.dart's `ValueListenableBuilder`s). Covers exactly
// what that split has to get right: the snapshot updates correctly, a
// relocation no longer wakes the provider's own `ChangeNotifier` listeners,
// duplicate/no-op updates don't over-notify, unrelated provider state
// changes still do notify, streak counting is unaffected, and a callback
// that fires after dispose is a no-op rather than a crash.
import 'package:aykitap/core/network/streak_endpoints.dart';
import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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

  group('progressListenable content', () {
    test('onRelocated publishes progress/page/cfi/href/toc into the snapshot',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 100, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.5,
          cfi: 'epubcfi(/6/4)',
          page: 10,
          totalPages: 20,
          href: 'ch3.xhtml'));

      final snapshot = provider.progressListenable.value;
      expect(snapshot.progress, 0.5);
      expect(snapshot.currentPage, 10);
      expect(snapshot.totalPages, 20);
      expect(snapshot.currentCfi, 'epubcfi(/6/4)');
      expect(snapshot.currentHref, 'ch3.xhtml');
      expect(snapshot.currentTocHref, 'ch3.xhtml');
      expect(snapshot.isAtLastPage, isFalse);
      expect(snapshot.isBookmarked, isFalse);

      // Still mirrored onto the provider's own plain getters — nothing that
      // reads those directly (chapter sheet, notes flow, ...) should notice
      // this split.
      expect(provider.currentPage, 10);
      expect(provider.totalPages, 20);
      expect(provider.progress, 0.5);
      expect(provider.currentCfi, 'epubcfi(/6/4)');

      await provider.saveAndClose();
      provider.dispose();
    });

    test('toggling a bookmark at the current position updates isBookmarked',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 101, bookTitle: 'Test');
      provider.onRelocated(_location(
          progress: 0.1, cfi: 'epubcfi(/6/1)', page: 1, totalPages: 10));

      expect(provider.progressListenable.value.isBookmarked, isFalse);

      await provider.toggleBookmark();
      expect(provider.progressListenable.value.isBookmarked, isTrue);

      await provider.toggleBookmark();
      expect(provider.progressListenable.value.isBookmarked, isFalse);

      await provider.saveAndClose();
      provider.dispose();
    });
  });

  group('notification scoping', () {
    test('onRelocated does not call the provider\'s own notifyListeners',
        () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 102, bookTitle: 'Test');

      var generalNotifyCount = 0;
      provider.addListener(() => generalNotifyCount++);

      provider.onRelocated(_location(
          progress: 0.2, cfi: 'epubcfi(/6/2)', page: 2, totalPages: 10));
      provider.onRelocated(_location(
          progress: 0.3, cfi: 'epubcfi(/6/3)', page: 3, totalPages: 10));

      expect(generalNotifyCount, 0);

      await provider.saveAndClose();
      provider.dispose();
    });

    test('a genuinely general change (eye-care) still calls notifyListeners',
        () async {
      // Not setTheme: that pushes into epubController.updateTheme, which
      // throws unless a real WebView has attached — no EpubViewer is mounted
      // in this provider-only test. setEyeCare is notify-only appearance
      // state (see reader_provider_appearance.dart), so it exercises the
      // same "not the progress notifier" path without that dependency.
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 103, bookTitle: 'Test');

      var generalNotifyCount = 0;
      provider.addListener(() => generalNotifyCount++);

      await provider.setEyeCare(0.4);

      expect(generalNotifyCount, greaterThan(0));

      await provider.saveAndClose();
      provider.dispose();
    });

    test(
        'an identical relocation reported twice notifies progressListenable '
        'only once', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 104, bookTitle: 'Test');

      var progressNotifyCount = 0;
      provider.progressListenable.addListener(() => progressNotifyCount++);

      final location = _location(
          progress: 0.5, cfi: 'epubcfi(/6/4)', page: 10, totalPages: 20);
      provider.onRelocated(location);
      provider.onRelocated(location);
      provider.onRelocated(location);

      expect(progressNotifyCount, 1);

      await provider.saveAndClose();
      provider.dispose();
    });
  });

  group('streak counting is unaffected by the notifier split', () {
    test('the first relocation after init is never counted as a page read',
        () async {
      final adapter = FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 105, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.3, cfi: 'epubcfi(/6/1)', page: 15, totalPages: 50));

      await Future<void>.delayed(const Duration(seconds: 1));
      await provider.saveAndClose();
      provider.dispose();
      // ReaderStreakPing.flushResidual (called from saveAndClose) fires
      // StreakService's report call without awaiting it — deliberately, so
      // closing the reader is never blocked on a network round trip. This
      // gives that fire-and-forget call a turn to actually reach the fake
      // adapter before asserting on what it received.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final report = adapter.requests
          .firstWhere((r) => r.path == StreakEndpoints.streakReport);
      expect((report.data as Map)['pages'], isNull);
    });

    test('a forward page move reports the page delta on the next streak flush',
        () async {
      final adapter = FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 106, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.1, cfi: 'epubcfi(/6/1)', page: 1, totalPages: 50));
      provider.onRelocated(_location(
          progress: 0.12, cfi: 'epubcfi(/6/2)', page: 3, totalPages: 50));

      await Future<void>.delayed(const Duration(seconds: 1));
      await provider.saveAndClose();
      provider.dispose();
      // See the identical comment above.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final report = adapter.requests
          .firstWhere((r) => r.path == StreakEndpoints.streakReport);
      expect((report.data as Map)['pages'], 2);
    });

    test('a backward page move never adds a page read', () async {
      final adapter = FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 107, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.4, cfi: 'epubcfi(/6/5)', page: 5, totalPages: 50));
      provider.onRelocated(_location(
          progress: 0.2, cfi: 'epubcfi(/6/2)', page: 2, totalPages: 50));

      await Future<void>.delayed(const Duration(seconds: 1));
      await provider.saveAndClose();
      provider.dispose();
      // See the identical comment above.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final report = adapter.requests
          .firstWhere((r) => r.path == StreakEndpoints.streakReport);
      expect((report.data as Map)['pages'], isNull);
    });
  });

  group('dispose safety', () {
    test(
        'onRelocated after dispose does not throw and leaves the snapshot '
        'untouched', () async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 108, bookTitle: 'Test');
      provider.onRelocated(_location(
          progress: 0.4, cfi: 'epubcfi(/6/4)', page: 4, totalPages: 10));

      await provider.saveAndClose();
      provider.dispose();
      // Whatever saveAndClose's own reset last published — captured only now,
      // since saveAndClose zeroes the position and republishes it too.
      final snapshotAfterDispose = provider.progressListenable.value;

      expect(
        () => provider.onRelocated(_location(
            progress: 0.9, cfi: 'epubcfi(/6/9)', page: 9, totalPages: 10)),
        returnsNormally,
      );
      expect(provider.progressListenable.value, snapshotAfterDispose);
    });

    test('a pending debounced save timer never fires after dispose', () async {
      final adapter = FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 109, bookTitle: 'Test');

      provider.onRelocated(_location(
          progress: 0.5, cfi: 'epubcfi(/6/5)', page: 5, totalPages: 10));
      // Dispose well inside the 2s debounce window, without saveAndClose —
      // _disposeCleanup must cancel the pending timer outright.
      provider.dispose();

      await Future<void>.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('book_109_page'), isNull);
      expect(
          adapter.requests.where((r) => r.path == StreakEndpoints.streakReport),
          isEmpty);
    });
  });

  group('widget rebuild scope', () {
    testWidgets(
        'a relocation rebuilds only the widget listening to '
        'progressListenable, not the Consumer<ReaderProvider> scope the '
        'EpubViewer subtree lives in', (tester) async {
      FakeDioAdapter.install();
      final provider = ReaderProvider();
      await provider.initialize(bookId: 110, bookTitle: 'Widget test');

      var consumerScopeBuilds = 0;
      var epubViewerStandInBuilds = 0;
      var progressBarBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<ReaderProvider>.value(
            value: provider,
            child: Consumer<ReaderProvider>(
              builder: (context, p, _) {
                consumerScopeBuilds++;
                return Column(
                  children: [
                    // Stands in for the EpubViewer (and the Positioned/
                    // SafeArea/Padding tree wrapping it in
                    // reader_view_body.dart) — both sit inside the same
                    // Consumer<ReaderProvider> scope as the chrome in
                    // production, which is exactly the scope a page
                    // relocation must no longer rebuild.
                    Builder(builder: (context) {
                      epubViewerStandInBuilds++;
                      return const SizedBox.shrink();
                    }),
                    ValueListenableBuilder<ReaderProgressSnapshot>(
                      valueListenable: p.progressListenable,
                      builder: (context, snapshot, _) {
                        progressBarBuilds++;
                        return Text(
                            '${snapshot.currentPage}/${snapshot.totalPages}');
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0/0'), findsOneWidget);
      final consumerBuildsAfterMount = consumerScopeBuilds;
      final epubViewerBuildsAfterMount = epubViewerStandInBuilds;

      provider.onRelocated(_location(
          progress: 0.5, cfi: 'epubcfi(/6/4)', page: 7, totalPages: 40));
      await tester.pump();

      expect(find.text('7/40'), findsOneWidget);
      expect(consumerScopeBuilds, consumerBuildsAfterMount,
          reason: 'a page relocation must not rebuild the '
              'Consumer<ReaderProvider> scope');
      expect(epubViewerStandInBuilds, epubViewerBuildsAfterMount,
          reason: 'a page relocation must not rebuild the EpubViewer '
              'subtree');
      expect(progressBarBuilds, greaterThan(1));

      await provider.saveAndClose();
      provider.dispose();
      // saveAndClose's own _saveProgress fires ReadingProgressReporter.report
      // unawaited — under a plain test() the real event loop just lets it
      // finish, but this FakeAsync zone needs an explicit elapse or its
      // still-pending Dio timer trips flutter_test's post-test
      // "no pending timers" invariant.
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
