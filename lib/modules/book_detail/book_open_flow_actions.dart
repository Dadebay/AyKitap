part of 'book_open_flow.dart';

/// [BookOpenFlow]'s login/top-up/download/export helpers — split out of
/// book_open_flow.dart to keep that file under the 200-line limit and keep
/// `read`/`buy` (the flow's single authority) together in the main file.
/// Pure mechanical move: every expression here is unchanged from before the
/// split, aside from `.instance` singleton lookups switching to
/// `context.read<T>()` for services registered as a `ChangeNotifierProvider`
/// in main.dart (see refactor-progress.md). `_downloadAndOpen` grabs its
/// providers once up front, before any `await`, so it never has to
/// re-justify that `context` is still mounted just to call `context.read`
/// again. `_login`'s two lookups used to run before any mounted check
/// existed, so one `if (!context.mounted) return false;` was added ahead of
/// them — the same pattern used in send_gift_sheet_actions.dart.
extension _BookOpenFlowActions on BookOpenFlow {
  /// Sends the user to login and reports whether they came back with a
  /// session. The login screen doesn't reliably pop a result (it can be
  /// dismissed by a back gesture after a successful verify), so the stored
  /// token is the authority, not the return value.
  Future<bool> _login() async {
    await context.push<bool>(const PhoneLoginScreen());
    if (!await AuthSession.isLoggedIn()) return false;
    if (!context.mounted) return false;
    // A fresh session means a fresh balance and a fresh purchased list —
    // both feed the very next access decision.
    await context.read<AccountService>().refresh();
    await context.read<BookAccessService>().refreshPurchased();
    if (!context.mounted) return false;
    onAccessChanged?.call();
    return true;
  }

  Future<void> _topUp() async {
    final balance = context.read<AccountService>().balanceManat;
    final price = book.price ?? 0;
    final pay = await InsufficientBalanceDialog.show(
      context,
      shortfallManat: balance == null ? null : price - balance,
    );
    if (!pay || !context.mounted) return;
    await startBalanceTopUp(context);
  }

  /// Owned or subscribed: get the file onto the device (skipping the
  /// network entirely if it's already there) and push the reader.
  Future<void> _downloadAndOpen({bool offerPurchasedExport = false}) async {
    final filesStore = context.read<DownloadedFilesStore>();
    final downloadService = context.read<BookDownloadService>();
    final downloadedBooksStore = context.read<DownloadedBooksStore>();
    final readingBooksStore = context.read<ReadingBooksStore>();
    final lastReadBookStore = context.read<LastReadBookStore>();

    await filesStore.load();

    final existing = filesStore.best(book.id);
    String path;
    String format;

    if (existing != null) {
      path = existing.path;
      format = existing.format;
    } else {
      final file = _pickFile();
      if (file == null) {
        if (context.mounted)
          context.showAppSnackBar(BookDetailStrings.noFileForBook,
              isError: true);
        return;
      }
      // Progress/cancellation are tracked in [BookDownloadService] itself
      // (keyed by book id, watched via Provider) rather than threaded back
      // through here — so a screen showing this book sees the same live
      // download whether it started the request or was (re)opened after
      // one already had.
      try {
        path =
            await downloadService.ensureDownloaded(bookId: book.id, file: file);
        format = file.fileFormat.toLowerCase();
      } on DioException catch (e) {
        // A cancel is the user's own doing — no error to report.
        if (e.type != DioExceptionType.cancel && context.mounted) {
          context.showAppSnackBar(BookDetailStrings.downloadFailed,
              isError: true);
        }
        return;
      } on ApiException catch (e) {
        if (context.mounted) context.showAppSnackBar(e.message, isError: true);
        return;
      }
    }

    // Kitaplygym → "Ýüklenenler" is backed by DownloadedBooksStore, so this
    // is what makes the book show up on that shelf.
    final shelfBook = LibraryBook.fromDetail(book);
    await downloadedBooksStore.add(shelfBook);
    await readingBooksStore.recordOpened(shelfBook);
    await lastReadBookStore.recordOpened(
      book: shelfBook,
      path: path,
      format: format,
    );
    if (!context.mounted) return;
    if (offerPurchasedExport) await _offerPurchasedExport(path);
    if (!context.mounted) return;
    _openReader(path: path, format: format);
  }

  /// The app-private copy is always kept for offline reading. A newly bought
  /// book can additionally be handed to the operating system's Files picker,
  /// where the reader chooses the final folder (Files, Downloads, Drive...).
  Future<void> _offerPurchasedExport(String path) async {
    final saveOutsideApp = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(BookDetailStrings.savePurchasedTitle),
        content: Text(BookDetailStrings.savePurchasedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(BookDetailStrings.keepInApp),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(BookDetailStrings.chooseSaveLocation),
          ),
        ],
      ),
    );
    if (saveOutsideApp != true || !context.mounted) return;
    try {
      await Share.shareXFiles([XFile(path)],
          fileNameOverrides: [path.split('/').last]);
    } catch (error) {
      if (context.mounted)
        context.showAppSnackBar(BookDetailStrings.saveToFilesError(error));
    }
  }

  /// The best format this book is available in — same priority the local
  /// store uses ([DownloadedFilesStore.formatPriority]: epub reflows best,
  /// cbz least).
  BookFile? _pickFile() {
    if (book.bookFiles.isEmpty) return null;
    for (final format in DownloadedFilesStore.formatPriority) {
      for (final file in book.bookFiles) {
        if (file.fileFormat.toLowerCase() == format) return file;
      }
    }
    return book.bookFiles.first;
  }

  void _openReader({required String path, required String format}) =>
      openCatalogBookFile(
        context,
        path: path,
        format: format,
        bookId: book.id,
        title: book.name,
        pageCount: book.pageCount,
        coverUrl: book.image == null || book.image!.isEmpty
            ? null
            : ApiConfig.resolveImageUrl(book.image!),
        heroTag: AppHeroTags.catalogBookCover(book.id),
      );
}
