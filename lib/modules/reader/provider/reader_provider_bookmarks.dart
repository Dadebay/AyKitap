part of 'reader_provider.dart';

/// Bookmarks (TZ §12.1) and in-book search (TZ §12.3). Bookmarks are held in
/// the app-wide [BookmarksStore] rather than locally, so the profile can
/// list every book's marks while the reader shows only this book's.
extension ReaderProviderBookmarks on ReaderProvider {
  List<Bookmark> get bookmarks =>
      BookmarksStore.instance.forBook(_bookId ?? -1);

  bool get isCurrentPageBookmarked =>
      _bookId != null &&
      _currentCfi.isNotEmpty &&
      BookmarksStore.instance.isBookmarked(_bookId!, _currentCfi);

  /// Toggles a bookmark at the current reading position (CFI). Returns true
  /// if a bookmark was added, false if one was removed.
  Future<bool> toggleBookmark() async {
    if (_bookId == null || _currentCfi.isEmpty) return false;
    final added = await BookmarksStore.instance.toggle(
      bookId: _bookId!,
      bookTitle: _bookTitle,
      cfi: _currentCfi,
      chapterTitle: currentChapterTitle ?? '',
      progress: _progress,
    );
    _notify();
    return added;
  }

  Future<void> removeBookmark(String id) async {
    await BookmarksStore.instance.remove(id);
    _notify();
  }

  void goToBookmark(String cfi) => epubController.display(cfi: cfi);

  Future<List<EpubSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    return epubController.search(query: query.trim());
  }
}
