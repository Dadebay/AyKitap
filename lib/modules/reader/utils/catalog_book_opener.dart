import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/analytics_service.dart';
import '../provider/reader_provider.dart';
import '../views/cbz_reader_screen.dart';
import '../views/reader_view.dart';
import 'pdf_book_opener.dart';

/// Pushes whichever reader handles [format] for an already-downloaded
/// catalogue book.
///
/// The real `/books/:id` id goes straight through as `bookId`: reading
/// progress, bookmarks and notes are keyed by it, so a catalogue book keeps
/// them across re-downloads. `stableBookKey` is only for the string-id
/// local imports ([OwnBooksStore]).
///
/// Top-level (rather than a `BookOpenFlow` method) so Kitaplygym's
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
      openPdfBook(context,
          filePath: path, title: title, bookId: bookId, realBookId: bookId);
    case 'cbz':
      context.push(CbzReaderScreen(
          filePath: path, title: title, bookId: bookId, realBookId: bookId));
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
