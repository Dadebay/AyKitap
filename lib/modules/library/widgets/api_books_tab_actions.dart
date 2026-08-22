part of 'api_books_tab.dart';

/// [_ApiBooksTabState]'s load/open/remove logic — split out of
/// api_books_tab.dart to keep that file under the 200-line limit. Lives as
/// an extension (not a subclass) so state fields stay declared once, in the
/// main file — see [_ApiBooksTabState._setState] for why `setState` itself
/// is called through a wrapper here rather than directly.
extension _ApiBooksTabActions on _ApiBooksTabState {
  /// Paint the saved reading shelf immediately, then let the backend refresh
  /// it in the background. Without this, an airplane-mode reader waits for a
  /// network timeout before seeing books that are already on the device.
  Future<void> _loadOfflineShadow() async {
    final fetcher = widget.offlineFetcher;
    if (fetcher == null) return;
    final books = await fetcher();
    if (!mounted || books.isEmpty) return;
    _setState(() {
      _books = books;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    _setState(() {
      _loading = true;
      _error = null;
      _needsLogin = false;
    });
    try {
      final books = await widget.fetcher();
      if (widget.syncsPurchasedAccess) {
        await BookAccessService.instance
            .replacePurchased(books.map((b) => b.id));
      }
      if (!mounted) return;
      await widget.cacheLoadedBooks?.call(books);
      if (!mounted) return;
      _setState(() {
        _books = books;
        _loading = false;
      });
    } on ApiException catch (e) {
      final offlineBooks = await widget.offlineFetcher?.call();
      if (!mounted) return;
      final hasOfflineBooks = offlineBooks != null && offlineBooks.isNotEmpty;
      _setState(() {
        _books = offlineBooks;
        _needsLogin = e.statusCode == 401 && !hasOfflineBooks;
        _error = !hasOfflineBooks && !_needsLogin ? e.message : null;
        _loading = false;
      });
    }
  }

  Future<void> _openBook(LibraryBook book) async {
    final results = await Connectivity().checkConnectivity();
    final isOffline =
        results.every((result) => result == ConnectivityResult.none);
    if (!isOffline) {
      if (!mounted) return;
      await context.push<bool>(
          CatalogBookDetailScreen(bookId: book.id, offlineBook: book));
      return;
    }

    await DownloadedFilesStore.instance.load();
    await BookAccessService.instance.load();
    final entry = DownloadedFilesStore.instance.best(book.id);
    if (entry == null || !BookAccessService.instance.canRead(book.id)) {
      if (mounted) {
        context.showAppSnackBar(LibraryStrings.offlineBookUnavailable,
            isError: true);
      }
      return;
    }
    await LastReadBookStore.instance.recordOpened(
      book: book,
      path: entry.path,
      format: entry.format,
    );
    if (!mounted) return;
    openCatalogBookFile(
      context,
      path: entry.path,
      format: entry.format,
      bookId: book.id,
      title: book.name,
      pageCount: book.pageCount,
    );
  }

  /// Long-press → confirm → [_remove]. The dialog shows the book's own cover
  /// so it's obvious *which* one is about to go, since a long-press on a
  /// dense shelf grid is easy to land on the wrong tile.
  Future<void> _confirmDelete(LibraryBook book) async {
    final removal = widget.removal;
    if (removal == null) return;
    final image = book.image;
    final choice = await showShelfDeleteDialog(
      context,
      message: removal.confirmMessage(book.name),
      coverUrl: image != null && image.isNotEmpty
          ? ApiConfig.resolveImageUrl(image)
          : null,
    );
    if (choice != ShelfDeleteChoice.delete || !mounted) return;
    await _remove(book, removal, LibraryStrings.bookDeleted(book.name));
  }

  /// The favorites shelf's heart button — the same `unlike` the long-press
  /// dialog runs, but straight away: a filled heart is a toggle everywhere
  /// else in the app (Book Detail's header included), and confirming a
  /// *like* would be heavier than the action deserves.
  Future<void> _unfavorite(LibraryBook book) async {
    await _remove(book, ShelfRemoval.favorite,
        LibraryStrings.removedFromFavorites(book.name));
  }

  /// Drops the cover from this shelf as soon as the call succeeds rather
  /// than waiting for a re-fetch; [ShelfRemoval.notifyShelvesChanged] then
  /// handles the *other* shelves showing the same state (a finished book
  /// also sits behind the reading shelf's filter). A failed call leaves the
  /// shelf untouched and shows the server's reason.
  Future<void> _remove(
      LibraryBook book, ShelfRemoval removal, String successMessage) async {
    try {
      await removal.apply(book.id);
      if (!mounted) return;
      _setState(() {
        _books = [...?_books?.where((b) => b.id != book.id)];
      });
      context.showAppSnackBar(successMessage);
      removal.notifyShelvesChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.message, isError: true);
    }
  }
}
