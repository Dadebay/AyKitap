import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/book_api_service.dart';
import '../../../core/services/downloaded_books_store.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../book_detail/book_open_flow.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import 'library_book_cover.dart';
import 'library_empty_state.dart';
import 'shelf_delete.dart';
import 'shelf_grid.dart';

/// No backend endpoint tracks this (see [DownloadedBooksStore]'s doc
/// comment) — the list is whatever's been saved to local storage, not a
/// fetch, so this just watches the store instead of loading/erroring like
/// [ApiBooksTab].
class DownloadedTab extends StatefulWidget {
  const DownloadedTab({super.key});

  @override
  State<DownloadedTab> createState() => _DownloadedTabState();
}

class _DownloadedTabState extends State<DownloadedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DownloadedBooksStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final books = context.watch<DownloadedBooksStore>().books;
    // Both drive the per-cover lock: access can lapse (subscription) and
    // files can be deleted from under the shelf.
    context.watch<BookAccessService>();
    context.watch<DownloadedFilesStore>();
    // Subscription state is restored from disk independently at boot, so
    // rebuild the locks once that offline cache becomes available.
    context.watch<SubscriptionService>();
    if (books.isEmpty) {
      return LibraryEmptyState(
          label: LibraryStrings.emptyDownloaded,
          sub: LibraryStrings.emptyDownloadedSub);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => LibraryBookCover(
          book: books[i],
          // Downloaded ≠ still readable: a book read on a subscription that
          // has since lapsed keeps its file but not its access, so the
          // cover carries a lock and opening it hits the normal gate.
          showLockWhenNoAccess: true,
          onTap: () => _openDownloaded(books[i]),
          onLongPress: () => _confirmDeleteDownload(books[i]),
        ),
      ),
    );
  }

  /// Opens the local file directly instead of routing through
  /// [CatalogBookDetailScreen] — that screen needs `GET /books/:id`, and
  /// the whole point of this shelf is that it works with no connection.
  /// Falls back to the detail page when the file is gone or access has
  /// lapsed, so the user lands somewhere that can explain why.
  Future<void> _openDownloaded(LibraryBook book) async {
    await DownloadedFilesStore.instance.load();
    final entry = DownloadedFilesStore.instance.best(book.id);
    if (entry == null || !BookAccessService.instance.canRead(book.id)) {
      if (!mounted) return;
      await context.push<bool>(CatalogBookDetailScreen(bookId: book.id));
      return;
    }
    if (!mounted) return;
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

  /// Hands the already-downloaded file to the OS share sheet so the user
  /// can save their own copy wherever they like (iOS Files / iCloud Drive,
  /// Android Downloads or Drive) — the app's private copy is untouched.
  Future<void> _saveToFiles(LibraryBook book) async {
    await DownloadedFilesStore.instance.load();
    final entry = DownloadedFilesStore.instance.best(book.id);
    if (entry == null) return;
    try {
      await Share.shareXFiles(
        [XFile(entry.path)],
        fileNameOverrides: [entry.path.split('/').last],
      );
    } catch (e) {
      if (mounted) context.showAppSnackBar(BookDetailStrings.saveToFilesError(e));
    }
  }

  /// Frees the device storage without touching the user's library: the file
  /// goes ([DownloadedFilesStore.removeBook] deletes it from disk) and the
  /// shelf entry goes, but a purchased book is still purchased and can be
  /// downloaded again.
  ///
  /// This is the same dialog every other shelf's long-press opens. It used
  /// to be a bottom sheet (save-to-Files / delete) with a second confirm
  /// dialog behind it — two steps, and unlike anywhere else in the library.
  /// The share action survives as the dialog's own alternative: purchased
  /// books are the user's to keep, so before freeing the space they can hand
  /// the on-disk file to the OS share sheet and pick "Save to Files" (iOS)
  /// or a Downloads-capable target (Android) themselves.
  Future<void> _confirmDeleteDownload(LibraryBook book) async {
    final image = book.image;
    final choice = await showShelfDeleteDialog(
      context,
      title: BookDetailStrings.deleteDownload,
      message: BookDetailStrings.deleteDownloadConfirm(book.name),
      coverUrl: image != null && image.isNotEmpty
          ? ApiConfig.resolveImageUrl(image)
          : null,
      extraLabel: BookDetailStrings.saveToFiles,
    );
    if (!mounted) return;
    switch (choice) {
      case ShelfDeleteChoice.cancel:
        return;
      case ShelfDeleteChoice.extra:
        await _saveToFiles(book);
        return;
      case ShelfDeleteChoice.delete:
        break;
    }
    await DownloadedFilesStore.instance.removeBook(book.id);
    await DownloadedBooksStore.instance.remove(book.id);
    if (mounted) context.showAppSnackBar(BookDetailStrings.downloadDeleted);
  }
}

/// A [LibraryScreen] tab backed by `GET /books/all` — [fetcher] is one of
/// [BookApiService.listBooks]'s `my_books`/`bought`/`wants_to` filters,
/// wired up per tab in [LibraryScreen]. Kept alive across tab switches
/// ([AutomaticKeepAliveClientMixin]) so flipping tabs back and forth doesn't
/// re-fetch every time.
class ApiBooksTab extends StatefulWidget {
  final Future<List<LibraryBook>> Function() fetcher;
  final String emptyLabel;
  final bool showProgress;
  final bool allowRemovingPurchasedBooks;

  /// Set on the "Satyn alnanlar" tab: its fetch *is* the purchased list, so
  /// the same response also refreshes [BookAccessService]'s offline cache
  /// rather than costing a second identical request.
  final bool syncsPurchasedAccess;

  /// Re-fetches whenever this notifies — e.g. the favorites tab passing
  /// [FavoritesSyncService.instance] so a like/unlike toggled from a book
  /// detail page elsewhere shows up here without a manual pull-to-refresh.
  /// This tab otherwise only reloads on that pull or its own retry button
  /// (`AutomaticKeepAliveClientMixin` keeps it alive across tab switches).
  final Listenable? refreshOn;

  /// Local shadow used when the reading shelf's backend request cannot run.
  final Future<List<LibraryBook>> Function()? offlineFetcher;
  final Future<void> Function(List<LibraryBook> books)? cacheLoadedBooks;

  /// A cached reading-shelf book must bypass `GET /books/:id` in airplane
  /// mode and open the downloaded file directly.
  final bool openLocalWhenOffline;

  /// What a long-press on one of this shelf's covers removes. Every shelf
  /// sets it — until it existed, a book could only be taken off the
  /// downloaded shelf, so there was no way to drop a finished book or a
  /// purchase without opening its detail page.
  final ShelfRemoval? removal;

  const ApiBooksTab({
    super.key,
    required this.fetcher,
    required this.emptyLabel,
    this.showProgress = false,
    this.allowRemovingPurchasedBooks = false,
    this.syncsPurchasedAccess = false,
    this.refreshOn,
    this.offlineFetcher,
    this.cacheLoadedBooks,
    this.openLocalWhenOffline = false,
    this.removal,
  });

  @override
  State<ApiBooksTab> createState() => _ApiBooksTabState();
}

class _ApiBooksTabState extends State<ApiBooksTab>
    with AutomaticKeepAliveClientMixin {
  List<LibraryBook>? _books;
  bool _loading = true;
  String? _error;

  /// Set when the fetch came back 401 — a signed-out visitor gets
  /// [LibraryLoginRequiredState] instead of the raw server error text.
  bool _needsLogin = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOfflineShadow();
    _load();
    widget.refreshOn?.addListener(_load);
  }

  /// Paint the saved reading shelf immediately, then let the backend refresh
  /// it in the background. Without this, an airplane-mode reader waits for a
  /// network timeout before seeing books that are already on the device.
  Future<void> _loadOfflineShadow() async {
    final fetcher = widget.offlineFetcher;
    if (fetcher == null) return;
    final books = await fetcher();
    if (!mounted || books.isEmpty) return;
    setState(() {
      _books = books;
      _loading = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    widget.refreshOn?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _needsLogin = false;
    });
    try {
      final books = await widget.fetcher();
      if (widget.syncsPurchasedAccess) {
        await BookAccessService.instance.replacePurchased(books.map((b) => b.id));
      }
      if (!mounted) return;
      await widget.cacheLoadedBooks?.call(books);
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } on ApiException catch (e) {
      final offlineBooks = await widget.offlineFetcher?.call();
      if (!mounted) return;
      final hasOfflineBooks = offlineBooks != null && offlineBooks.isNotEmpty;
      setState(() {
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
      setState(() {
        _books = [...?_books?.where((b) => b.id != book.id)];
      });
      context.showAppSnackBar(successMessage);
      removal.notifyShelvesChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_needsLogin) {
      return LibraryLoginRequiredState(onLoggedIn: _load);
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: _load,
                  child: Text(LibraryStrings.retry,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    final books = _books ?? const [];
    if (books.isEmpty) return LibraryEmptyState(label: widget.emptyLabel);
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        child: ShelfGrid(
          itemCount: books.length,
          // Keyed by book id — without it, removing an item (unfavoriting,
          // removing a purchase) shifts every following cover into the
          // slot the removed one used to hold, and Flutter's default
          // position-based reconciliation can keep that slot's element
          // (and pending gesture/image state) around across the shrink
          // instead of cleanly rebuilding it for the book now there.
          itemBuilder: (context, i) => LibraryBookCover(
            key: ValueKey(books[i].id),
            book: books[i],
            showProgress: widget.showProgress,
            canRemoveFromPurchased: widget.allowRemovingPurchasedBooks,
            onPurchasedBookRemoved: _load,
            onTap: widget.openLocalWhenOffline
                ? () => _openBook(books[i])
                : null,
            onLongPress:
                widget.removal == null ? null : () => _confirmDelete(books[i]),
            // Derived rather than a second flag: the heart *is* this
            // shelf's removal, so the two can't drift apart.
            onUnfavorite: widget.removal == ShelfRemoval.favorite
                ? () => _unfavorite(books[i])
                : null,
          ),
        ),
      ),
    );
  }
}
