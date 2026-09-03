// [ReaderProgressSnapshot] equality is load-bearing: [ValueNotifier.value]'s
// setter skips `notifyListeners` whenever the new value `==` the old one, and
// that's the only thing that stops an identical relocation reported twice
// from waking every widget listening to `ReaderProvider.progressListenable`
// (see reader_provider_callbacks.dart's `_updateProgressSnapshot`). These
// tests exist so a field added to the class later doesn't silently fall out
// of `==`/`hashCode` and reintroduce that rebuild.
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderProgressSnapshot equality', () {
    const a = ReaderProgressSnapshot(
      progress: 0.5,
      currentPage: 10,
      totalPages: 20,
      currentCfi: 'epubcfi(/6/4)',
      currentHref: 'ch1.xhtml',
      currentTocHref: 'ch1.xhtml#a',
      currentChapterTitle: 'Chapter 1',
      isBookmarked: true,
    );

    test('two snapshots with identical fields are equal', () {
      const b = ReaderProgressSnapshot(
        progress: 0.5,
        currentPage: 10,
        totalPages: 20,
        currentCfi: 'epubcfi(/6/4)',
        currentHref: 'ch1.xhtml',
        currentTocHref: 'ch1.xhtml#a',
        currentChapterTitle: 'Chapter 1',
        isBookmarked: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test(
        'a differing progress/page/cfi/href/chapter/bookmark field each '
        'break equality on their own', () {
      expect(a, isNot(a.copyForTest(progress: 0.6)));
      expect(a, isNot(a.copyForTest(currentPage: 11)));
      expect(a, isNot(a.copyForTest(totalPages: 21)));
      expect(a, isNot(a.copyForTest(currentCfi: 'epubcfi(/6/6)')));
      expect(a, isNot(a.copyForTest(currentHref: 'ch2.xhtml')));
      expect(a, isNot(a.copyForTest(currentTocHref: 'ch2.xhtml#a')));
      expect(a, isNot(a.copyForTest(currentChapterTitle: 'Chapter 2')));
      expect(a, isNot(a.copyForTest(currentChapterTitle: null)));
      expect(a, isNot(a.copyForTest(isAtLastPage: true)));
      expect(a, isNot(a.copyForTest(isBookmarked: false)));
    });

    test('default construction matches a fresh, unopened reader', () {
      const snapshot = ReaderProgressSnapshot();
      expect(snapshot.progress, 0.0);
      expect(snapshot.currentPage, 0);
      expect(snapshot.totalPages, 0);
      expect(snapshot.currentCfi, '');
      expect(snapshot.currentHref, '');
      expect(snapshot.currentTocHref, '');
      expect(snapshot.currentChapterTitle, isNull);
      expect(snapshot.isAtLastPage, isFalse);
      expect(snapshot.isBookmarked, isFalse);
    });
  });
}

/// Test-only helper: builds a copy of this snapshot with one field swapped,
/// so each equality case above only has to name what's different.
extension _CopyForTest on ReaderProgressSnapshot {
  ReaderProgressSnapshot copyForTest({
    double? progress,
    int? currentPage,
    int? totalPages,
    String? currentCfi,
    String? currentHref,
    String? currentTocHref,
    Object? currentChapterTitle = _unset,
    bool? isAtLastPage,
    bool? isBookmarked,
  }) {
    return ReaderProgressSnapshot(
      progress: progress ?? this.progress,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentCfi: currentCfi ?? this.currentCfi,
      currentHref: currentHref ?? this.currentHref,
      currentTocHref: currentTocHref ?? this.currentTocHref,
      currentChapterTitle: identical(currentChapterTitle, _unset)
          ? this.currentChapterTitle
          : currentChapterTitle as String?,
      isAtLastPage: isAtLastPage ?? this.isAtLastPage,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

const _unset = Object();
