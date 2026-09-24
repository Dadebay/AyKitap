import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/book_open_history.dart';
import '../../../core/services/downloaded_books_store.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import '../../main_nav/widgets/wheel_nav_bar.dart';
import '../../reader/utils/catalog_book_opener.dart';
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
    BookOpenHistory.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // [DownloadedBooksStore] orders by when the *file* arrived, which stops
    // saying anything useful once a few books have been downloaded and read
    // in a different order — so the book last actually opened comes first.
    final books = context
        .watch<BookOpenHistory>()
        .sortByRecency(context.watch<DownloadedBooksStore>().books);
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
      // Clears the wheel the Scaffold draws over this content — see
      // [WheelNavBar.clearance].
      padding: EdgeInsets.only(bottom: WheelNavBar.clearance(context) + 16),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => LibraryBookCover(
          book: books[i],
          heroShelf: 'downloaded',
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
    final image = book.image;
    final coverUrl = image != null && image.isNotEmpty
        ? ApiConfig.resolveImageUrl(image)
        : null;
    final heroTag = AppHeroTags.libraryShelfBookCover('downloaded', book.id);
    await DownloadedFilesStore.instance.load();
    final entry = DownloadedFilesStore.instance.best(book.id);
    if (entry == null || !BookAccessService.instance.canRead(book.id)) {
      if (!mounted) return;
      await context.pushHero<bool>(CatalogBookDetailScreen(
        bookId: book.id,
        heroTag: heroTag,
        initialCoverUrl: coverUrl,
      ));
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
      coverUrl: coverUrl,
      heroTag: heroTag,
    );
  }

  /// Frees the device storage without touching the user's library: the file
  /// goes ([DownloadedFilesStore.removeBook] deletes it from disk) and the
  /// shelf entry goes, but a purchased book is still purchased and can be
  /// downloaded again.
  ///
  /// This is the same dialog every other shelf's long-press opens. It used
  /// to carry a second action that handed the on-disk file to the OS share
  /// sheet, so the reader could keep a copy outside the app before freeing
  /// the space. That action is gone: a catalogue book is licensed reading
  /// inside this app, and the share sheet was a way to walk a DRM-free file
  /// of it straight out. Deleting still leaves the book itself untouched —
  /// it can be downloaded again at any time.
  Future<void> _confirmDeleteDownload(LibraryBook book) async {
    final image = book.image;
    final choice = await showShelfDeleteDialog(
      context,
      title: BookDetailStrings.deleteDownload,
      message: BookDetailStrings.deleteDownloadConfirm(book.name),
      coverUrl: image != null && image.isNotEmpty
          ? ApiConfig.resolveImageUrl(image)
          : null,
    );
    if (!mounted) return;
    if (choice != ShelfDeleteChoice.delete) return;
    await DownloadedFilesStore.instance.removeBook(book.id);
    await DownloadedBooksStore.instance.remove(book.id);
    if (mounted) context.showAppSnackBar(BookDetailStrings.downloadDeleted);
  }
}
