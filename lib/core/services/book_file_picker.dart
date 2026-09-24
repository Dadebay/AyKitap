import '../models/book_detail.dart';
import 'downloaded_files_store.dart';

/// The one file of a book the app treats as *the* book.
///
/// A catalogue book can carry several files — the same work as epub, pdf and
/// cbz — and [DownloadedFilesStore.formatPriority] is the order the reader
/// prefers them in (epub reflows best, cbz least). Both buying and opening go
/// through this, so the file that is paid for is the file that opens.
///
/// Returns null for a book with no files at all, which is a book that cannot
/// be read and must not be sold.
BookFile? preferredBookFile(List<BookFile> files) {
  if (files.isEmpty) return null;
  for (final format in DownloadedFilesStore.formatPriority) {
    for (final file in files) {
      if (file.fileFormat.toLowerCase() == format) return file;
    }
  }
  return files.first;
}
