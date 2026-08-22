import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/downloaded_books_store.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/services/last_read_book_store.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
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
      if (mounted)
        context.showAppSnackBar(BookDetailStrings.saveToFilesError(e));
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
