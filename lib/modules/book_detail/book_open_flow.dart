import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/strings/book_detail_strings.dart';
import '../../core/models/book_detail.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/account_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/book_download_service.dart';
import '../../core/services/downloaded_books_store.dart';
import '../../core/services/downloaded_files_store.dart';
import '../../core/services/last_read_book_store.dart';
import '../../core/services/reading_books_store.dart';
import '../../core/widgets/app_snackbar.dart';
import '../auth/phone_login_screen.dart';
import '../payment/balance_top_up.dart';
import '../payment/book_purchase_screen.dart';
import '../payment/widgets/insufficient_balance_dialog.dart';
import '../reader/provider/reader_provider.dart';
import '../reader/utils/pdf_book_opener.dart';
import '../reader/views/cbz_reader_screen.dart';
import '../reader/views/reader_view.dart';

/// Everything that happens between tapping "Oku" and a reader appearing:
/// the access gate, the login/top-up/purchase detours it can send the user
/// on, the download, and the hand-off to whichever reader the file's format
/// calls for.
///
/// Lives outside [CatalogBookDetailScreen] so that screen stays a screen —
/// and so the same flow can be reused from anywhere else that opens a
/// catalogue book (a downloaded shelf tap, a notification).
class BookOpenFlow {
  final BuildContext context;
  final BookDetail book;

  /// Fired after anything that could change the access verdict (a login, a
  /// completed purchase) so the CTA row can re-resolve.
  final VoidCallback? onAccessChanged;

  const BookOpenFlow({
    required this.context,
    required this.book,
    this.onAccessChanged,
  });

  /// The "Oku" path: resolve access, clear whatever is in the way, then
  /// download (if needed) and open.
  ///
  /// [_retries] guards the one place this re-enters itself — after a login
  /// or purchase the verdict is re-resolved, and a backend that keeps
  /// answering "needsPurchase" must not turn that into an endless loop of
  /// checkout screens.
  Future<void> read({int retries = 2, bool offerPurchasedExport = false}) async {
    final access = await BookAccessService.instance.resolve(book);
    if (!context.mounted) return;

    switch (access) {
      case BookAccess.purchased:
        await _downloadAndOpen(offerPurchasedExport: offerPurchasedExport);
      case BookAccess.subscription:
        await _downloadAndOpen();

      case BookAccess.needsLogin:
        if (retries <= 0) return;
        final loggedIn = await _login();
        if (loggedIn && context.mounted) await read(retries: retries - 1);

      case BookAccess.needsPurchase:
        if (retries <= 0) return;
        final bought = await buy();
        if (bought && context.mounted) await read(retries: retries - 1);

      case BookAccess.needsTopUp:
        await _topUp();
        if (context.mounted) onAccessChanged?.call();
    }
  }

  /// The "Satyn al" path. Returns true when the book ends up owned — which
  /// is also the case when it already was (a second tap while the CTA was
  /// stale), so the caller can just go on to opening it.
  Future<bool> buy({int retries = 2}) async {
    final access = await BookAccessService.instance.resolve(book);
    if (!context.mounted) return false;

    switch (access) {
      case BookAccess.purchased:
        return true;

      case BookAccess.needsLogin:
        if (retries <= 0) return false;
        final loggedIn = await _login();
        if (!loggedIn || !context.mounted) return false;
        return buy(retries: retries - 1);

      case BookAccess.needsTopUp:
        await _topUp();
        if (!context.mounted) return false;
        onAccessChanged?.call();
        // The top-up may well have covered the price — re-resolve once
        // rather than making the user tap "Satyn al" again.
        if (retries <= 0) return false;
        final resolved = await BookAccessService.instance.resolve(book);
        if (resolved != BookAccess.needsPurchase || !context.mounted) return false;
        return buy(retries: retries - 1);

      // An active subscriber can still buy a book outright — that's the
      // point of buying one: it outlives the subscription.
      case BookAccess.subscription:
      case BookAccess.needsPurchase:
        final bought = await context.push<bool>(BookPurchaseScreen(book: book));
        if (!context.mounted) return false;
        onAccessChanged?.call();
        return bought == true;
    }
  }

  /// Sends the user to login and reports whether they came back with a
  /// session. The login screen doesn't reliably pop a result (it can be
  /// dismissed by a back gesture after a successful verify), so the stored
  /// token is the authority, not the return value.
  Future<bool> _login() async {
    await context.push<bool>(const PhoneLoginScreen());
    if (!await AuthSession.isLoggedIn()) return false;
    // A fresh session means a fresh balance and a fresh purchased list —
    // both feed the very next access decision.
    await AccountService.instance.refresh();
    await BookAccessService.instance.refreshPurchased();
    if (!context.mounted) return false;
    onAccessChanged?.call();
    return true;
  }

  Future<void> _topUp() async {
    final balance = AccountService.instance.balanceManat;
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
    final store = DownloadedFilesStore.instance;
    await store.load();

    final existing = store.best(book.id);
    String path;
    String format;

    if (existing != null) {
      path = existing.path;
      format = existing.format;
    } else {
      final file = _pickFile();
      if (file == null) {
        if (context.mounted) context.showAppSnackBar(BookDetailStrings.noFileForBook, isError: true);
        return;
      }
      // Progress/cancellation are tracked in [BookDownloadService] itself
      // (keyed by book id, watched via Provider) rather than threaded back
      // through here — so a screen showing this book sees the same live
      // download whether it started the request or was (re)opened after
      // one already had.
      try {
        path = await BookDownloadService.instance.ensureDownloaded(bookId: book.id, file: file);
        format = file.fileFormat.toLowerCase();
      } on DioException catch (e) {
        // A cancel is the user's own doing — no error to report.
        if (e.type != DioExceptionType.cancel && context.mounted) {
          context.showAppSnackBar(BookDetailStrings.downloadFailed, isError: true);
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
    await DownloadedBooksStore.instance.add(shelfBook);
    await ReadingBooksStore.instance.recordOpened(shelfBook);
    await LastReadBookStore.instance.recordOpened(
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
      await Share.shareXFiles([XFile(path)], fileNameOverrides: [path.split('/').last]);
    } catch (error) {
      if (context.mounted) context.showAppSnackBar(BookDetailStrings.saveToFilesError(error));
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

  void _openReader({required String path, required String format}) => openCatalogBookFile(
        context,
        path: path,
        format: format,
        bookId: book.id,
        title: book.name,
        pageCount: book.pageCount,
      );
}

/// Pushes whichever reader handles [format] for an already-downloaded
/// catalogue book.
///
/// The real `/books/:id` id goes straight through as `bookId`: reading
/// progress, bookmarks and notes are keyed by it, so a catalogue book keeps
/// them across re-downloads. `stableBookKey` is only for the string-id
/// local imports ([OwnBooksStore]).
///
/// Top-level (rather than a [BookOpenFlow] method) so Kitaplygym's
/// "Ýüklenenler" shelf can open a downloaded book straight from disk —
/// that shelf has only a [LibraryBook], and going via the detail screen
/// would need `GET /books/:id`, which is exactly what isn't available in
/// airplane mode.
void openCatalogBookFile(
  BuildContext context, {
  required String path,
  required String format,
  required int bookId,
  required String title,
  int? pageCount,
}) {
  AnalyticsService.instance.logBookOpened(id: '$bookId', format: format);
  switch (format) {
    case 'pdf':
      openPdfBook(context, filePath: path, title: title, bookId: bookId, realBookId: bookId);
    case 'cbz':
      context.push(CbzReaderScreen(filePath: path, title: title, bookId: bookId, realBookId: bookId));
    default:
      context.push(
        ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
          child: ReaderScreen(
            bookPath: path,
            bookId: bookId,
            bookTitle: title,
            bookPages: pageCount,
            realBookId: bookId,
          ),
        ),
      );
  }
}
