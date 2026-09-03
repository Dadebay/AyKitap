import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/analytics_service.dart';
import '../provider/reader_provider.dart';
import '../views/cbz_reader_screen.dart';
import '../views/reader_view.dart';
import '../widgets/reader_entrance.dart';
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
  String? coverUrl,
  String? heroTag,
}) {
  AnalyticsService.instance.logBookOpened(
    id: '$bookId',
    format: format,
    source: 'catalog',
  );
  // Temporary diagnostic for the "kicked out on the loading screen" crash
  // report — see PdfOpeningScreen._resolve's comment. Logged right at the
  // format dispatch so it's clear which reader pipeline is about to run.
  final file = File(path);
  log('🔍 [BookOpen] openCatalogBookFile bookId=$bookId format=$format '
      'exists=${file.existsSync()} '
      'sizeBytes=${file.existsSync() ? file.lengthSync() : -1}');
  switch (format) {
    case 'pdf':
      openPdfBook(
        context,
        filePath: path,
        title: title,
        bookId: bookId,
        realBookId: bookId,
        coverUrl: coverUrl,
        heroTag: heroTag,
      );
    case 'cbz':
      pushReaderRoute(
        context,
        coverUrl: coverUrl,
        heroTag: heroTag,
        reader: CbzReaderScreen(
          filePath: path,
          title: title,
          bookId: bookId,
          realBookId: bookId,
        ),
      );
    default:
      pushReaderRoute(
        context,
        coverUrl: coverUrl,
        heroTag: heroTag,
        reader: ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
          child: ReaderScreen(
            bookPath: path,
            bookId: bookId,
            bookTitle: title,
            coverUrl: coverUrl,
            bookPages: pageCount,
            realBookId: bookId,
          ),
        ),
      );
  }
}
