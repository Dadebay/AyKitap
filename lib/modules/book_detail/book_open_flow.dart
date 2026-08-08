import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  /// Download progress as 0–1, or null when nothing is downloading. Drives
  /// the percentage on the CTA button.
  final void Function(double? progress)? onProgress;

  /// Handed back when a download starts so the caller can cancel it.
  final void Function(CancelToken? token)? onCancelToken;

  /// Fired after anything that could change the access verdict (a login, a
  /// completed purchase) so the CTA row can re-resolve.
  final VoidCallback? onAccessChanged;

  const BookOpenFlow({
    required this.context,
    required this.book,
    this.onProgress,
    this.onCancelToken,
    this.onAccessChanged,
  });

  /// The "Oku" path: resolve access, clear whatever is in the way, then
  /// download (if needed) and open.
  ///
  /// [_retries] guards the one place this re-enters itself — after a login
  /// or purchase the verdict is re-resolved, and a backend that keeps
  /// answering "needsPurchase" must not turn that into an endless loop of
  /// checkout screens.
  Future<void> read({int retries = 2}) async {
    final access = await BookAccessService.instance.resolve(book);
    if (!context.mounted) return;

    switch (access) {
      case BookAccess.purchased:
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
  Future<void> _downloadAndOpen() async {
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
      final cancelToken = CancelToken();
      onCancelToken?.call(cancelToken);
      onProgress?.call(0);
      try {
        path = await BookDownloadService.instance.ensureDownloaded(
          bookId: book.id,
          file: file,
          cancelToken: cancelToken,
          onProgress: (received, total) {
            if (total > 0) onProgress?.call(received / total);
          },
        );
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
      } finally {
        onProgress?.call(null);
        onCancelToken?.call(null);
      }
    }

    // Kitaplygym → "Ýüklenenler" is backed by DownloadedBooksStore, so this
    // is what makes the book show up on that shelf.
    await DownloadedBooksStore.instance.add(LibraryBook.fromDetail(book));
    await LastReadBookStore.instance.recordOpened(
      book: LibraryBook.fromDetail(book),
      path: path,
      format: format,
    );
    if (!context.mounted) return;
    _openReader(path: path, format: format);
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
      openPdfBook(context, filePath: path, title: title, bookId: bookId);
    case 'cbz':
      context.push(CbzReaderScreen(filePath: path, title: title, bookId: bookId));
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
