part of 'book_download_service.dart';

/// [BookDownloadService]'s actual download implementation — split out of
/// that file to keep it under the 200-line limit. Pure mechanical move:
/// every expression here is unchanged from before the split.
extension _BookDownloadServiceImpl on BookDownloadService {
  Future<String> _ensureDownloaded(
      {required int bookId, required BookFile file}) async {
    try {
      final store = DownloadedFilesStore.instance;
      await store.load();

      final existing = store.find(bookId, file.fileFormat);
      if (existing != null && await File(existing.path).exists())
        return existing.path;

      final dir = await _bookDir(bookId);
      final destPath = '${dir.path}/${_safeFileName(file)}';
      // A leftover file with no store entry (killed mid-rename, prefs
      // cleared) is still a complete download — `.part` is what a partial
      // one looks like, and that never gets this name.
      if (!await File(destPath).exists()) {
        final cancelToken = CancelToken();
        _cancelTokens[bookId] = cancelToken;
        _progress[bookId] = 0;
        _notify();
        try {
          await _download(
            file: file,
            destPath: destPath,
            cancelToken: cancelToken,
            onProgress: (received, total) {
              if (total > 0) {
                _progress[bookId] = received / total;
                _notify();
              }
            },
          );
        } finally {
          _cancelTokens.remove(bookId);
        }
      }

      await store.add(DownloadedFileEntry(
        bookId: bookId,
        format: file.fileFormat.toLowerCase(),
        path: destPath,
        sizeBytes: await File(destPath).length(),
        downloadedAt: DateTime.now(),
      ));
      return destPath;
    } finally {
      _inFlight.remove(bookId);
      _progress.remove(bookId);
      _notify();
    }
  }

  /// Fetches a fresh presigned link and streams it to `<dest>.part`, then
  /// renames. The rename is what makes "the file exists" mean "the file is
  /// complete" — an interrupted download leaves only the `.part` behind,
  /// so it can never be mistaken for a finished one and opened as a corrupt
  /// book.
  Future<void> _download({
    required BookFile file,
    required String destPath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final tmpPath = '$destPath.part';
    try {
      var link = await BookFileApiService.getFileLink(file.fileKey);
      if (link.url.isEmpty)
        throw const ApiException('Kitabyň faýly tapylmady.');
      try {
        await BookDownloadService._downloader.download(link.url, tmpPath,
            onReceiveProgress: onProgress, cancelToken: cancelToken);
      } on DioException catch (e) {
        // The signature is only good for ~10 minutes. A download that
        // started near the end of that window (or a link that sat around
        // while the user read a dialog) comes back 403 — one fresh link and
        // one retry covers it without looping.
        final status = e.response?.statusCode;
        if (e.type == DioExceptionType.cancel ||
            (status != 403 && status != 401)) rethrow;
        link = await BookFileApiService.getFileLink(file.fileKey);
        await BookDownloadService._downloader.download(link.url, tmpPath,
            onReceiveProgress: onProgress, cancelToken: cancelToken);
      }

      final tmp = File(tmpPath);
      // `file_size` is 0 for some catalogue rows, which means "unknown",
      // not "empty" — only treat a mismatch as corruption when we were
      // actually told a size.
      if (file.fileSize > 0) {
        final downloaded = await tmp.length();
        if (downloaded != file.fileSize) {
          await tmp.delete();
          throw const ApiException('Faýl doly ýüklenmedi. Gaýtadan synanyşyň.');
        }
      }
      await tmp.rename(destPath);
    } on DioException catch (e) {
      await _deleteQuietly(tmpPath);
      if (e.type == DioExceptionType.cancel) rethrow;
      throw ApiException.fromDioException(e);
    } catch (e) {
      await _deleteQuietly(tmpPath);
      if (e is ApiException) rethrow;
      throw ApiException('Kitap ýüklenmedi: $e');
    }
  }

  Future<Directory> _bookDir(int bookId) async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/books/$bookId');
    if (!await dir.exists()) await dir.create(recursive: true);
    // Android's media scanner would otherwise index a CBZ's extracted
    // pages into the user's gallery.
    if (Platform.isAndroid) {
      final noMedia = File('${support.path}/books/.nomedia');
      if (!await noMedia.exists()) {
        try {
          await noMedia.create();
        } catch (_) {}
      }
    }
    return dir;
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode)
        debugPrint('BookDownloadService: could not clean up $path — $e');
    }
  }
}

/// The tail of the `file_key`, stripped of anything that isn't safe in a
/// path. The extension is forced to match `file_format` so the readers
/// (and [OwnBooksStore]-style extension sniffing) always agree with the
/// store entry.
String _safeFileName(BookFile file) {
  final tail = file.fileKey.split('/').last;
  var name = tail.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (name.isEmpty || name == '.') name = 'book';
  final ext = '.${file.fileFormat.toLowerCase()}';
  if (!name.toLowerCase().endsWith(ext)) name = '$name$ext';
  return name;
}
