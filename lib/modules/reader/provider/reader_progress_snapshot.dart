import 'package:flutter/foundation.dart';

/// Immutable snapshot of the reader's current reading position — every field
/// a single page relocation touches: progress/page/CFI, the chapter it falls
/// in, and whether that exact spot is bookmarked.
///
/// Kept separate from [ReaderProvider]'s own [ChangeNotifier] state so a page
/// turn can publish just this (via `ReaderProvider.progressListenable`)
/// without waking every `Consumer`/`Selector` listening to the provider for
/// its rarer, book-wide state (theme, chapters list, load state, chrome
/// visibility, ...). See reader_view_chrome.dart for the widgets that read
/// it directly instead of the ambient `Consumer<ReaderProvider>`.
@immutable
class ReaderProgressSnapshot {
  final double progress;
  final int currentPage;
  final int totalPages;
  final String currentCfi;
  final String currentHref;
  final String currentTocHref;
  final String? currentChapterTitle;
  final bool isAtLastPage;
  final bool isBookmarked;

  const ReaderProgressSnapshot({
    this.progress = 0.0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentCfi = '',
    this.currentHref = '',
    this.currentTocHref = '',
    this.currentChapterTitle,
    this.isAtLastPage = false,
    this.isBookmarked = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderProgressSnapshot &&
          progress == other.progress &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages &&
          currentCfi == other.currentCfi &&
          currentHref == other.currentHref &&
          currentTocHref == other.currentTocHref &&
          currentChapterTitle == other.currentChapterTitle &&
          isAtLastPage == other.isAtLastPage &&
          isBookmarked == other.isBookmarked);

  @override
  int get hashCode => Object.hash(
        progress,
        currentPage,
        totalPages,
        currentCfi,
        currentHref,
        currentTocHref,
        currentChapterTitle,
        isAtLastPage,
        isBookmarked,
      );

  @override
  String toString() =>
      'ReaderProgressSnapshot(progress: $progress, page: $currentPage/$totalPages, '
      'cfi: $currentCfi, href: $currentHref, tocHref: $currentTocHref, '
      'chapter: $currentChapterTitle, isAtLastPage: $isAtLastPage, isBookmarked: $isBookmarked)';
}
