import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/library_book.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/book_api_service.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/downloaded_books_store.dart';
import '../../../core/services/downloaded_files_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../book_detail/book_open_flow.dart';
import '../../book_detail/catalog_book_detail_screen.dart';
import 'library_book_cover.dart';
import 'library_empty_state.dart';
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
    openCatalogBookFile(
      context,
      path: entry.path,
      format: entry.format,
      bookId: book.id,
      title: book.name,
      pageCount: book.pageCount,
    );
  }

  /// Frees the device storage without touching the user's library: the file
  /// goes ([DownloadedFilesStore.removeBook] deletes it from disk) and the
  /// shelf entry goes, but a purchased book is still purchased and can be
  /// downloaded again.
  Future<void> _confirmDeleteDownload(LibraryBook book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(BookDetailStrings.deleteDownload, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          BookDetailStrings.deleteDownloadConfirm(book.name),
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BookDetailStrings.cancel, style: TextStyle(color: AppColors.grey2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(BookDetailStrings.remove, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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

  const ApiBooksTab({
    super.key,
    required this.fetcher,
    required this.emptyLabel,
    this.showProgress = false,
    this.allowRemovingPurchasedBooks = false,
    this.syncsPurchasedAccess = false,
  });

  @override
  State<ApiBooksTab> createState() => _ApiBooksTabState();
}

class _ApiBooksTabState extends State<ApiBooksTab>
    with AutomaticKeepAliveClientMixin {
  List<LibraryBook>? _books;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await widget.fetcher();
      if (widget.syncsPurchasedAccess) {
        await BookAccessService.instance.replacePurchased(books.map((b) => b.id));
      }
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
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
          itemBuilder: (context, i) => LibraryBookCover(
            book: books[i],
            showProgress: widget.showProgress,
            canRemoveFromPurchased: widget.allowRemovingPurchasedBooks,
            onPurchasedBookRemoved: _load,
          ),
        ),
      ),
    );
  }
}
