import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/book_detail.dart';
import '../network/api_exception.dart';
import 'book_file_api_service.dart';
import 'downloaded_files_store.dart';

/// Pulls a catalogue book's file onto the device and hands back a local
/// path the readers can open — online once, offline forever after.
///
/// Files land in the application *support* directory rather than documents:
/// on iOS that keeps them out of the Files app (which
/// `LSSupportsOpeningDocumentsInPlace` exposes Documents to) and out of
/// iCloud backup, which is the "hidden place on the phone" this flow is
/// supposed to use. On Android both are app-private either way.
class BookDownloadService {
  BookDownloadService._();
  static final instance = BookDownloadService._();

  /// A bare Dio with no `baseUrl` and, crucially, **no auth interceptor**:
  /// the presigned media URL carries its own signature, and sending a
  /// bearer token alongside it can make the media host reject the request.
  static final Dio _downloader = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    // A big CBZ over a slow connection can go quiet for a while between
    // chunks; the API client's 15s would kill it mid-download.
    receiveTimeout: const Duration(minutes: 5),
  ));

  /// Returns the on-disk path of [file] for [bookId], downloading it first
  /// if it isn't already there.
  ///
  /// A file that's already on disk short-circuits before any network call,
  /// so a second "Oku" (or any open in airplane mode) never touches the
  /// network. Throws [ApiException] when the link or the download fails.
  Future<String> ensureDownloaded({
    required int bookId,
    required BookFile file,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final store = DownloadedFilesStore.instance;
    await store.load();

    final existing = store.find(bookId, file.fileFormat);
    if (existing != null && await File(existing.path).exists()) return existing.path;

    final dir = await _bookDir(bookId);
    final destPath = '${dir.path}/${_safeFileName(file)}';
    // A leftover file with no store entry (killed mid-rename, prefs
    // cleared) is still a complete download — `.part` is what a partial
    // one looks like, and that never gets this name.
    if (!await File(destPath).exists()) {
      await _download(file: file, destPath: destPath, onProgress: onProgress, cancelToken: cancelToken);
    }

    await store.add(DownloadedFileEntry(
      bookId: bookId,
      format: file.fileFormat.toLowerCase(),
      path: destPath,
      sizeBytes: await File(destPath).length(),
      downloadedAt: DateTime.now(),
    ));
    return destPath;
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
      if (link.url.isEmpty) throw const ApiException('Kitabyň faýly tapylmady.');
      try {
        await _downloader.download(link.url, tmpPath, onReceiveProgress: onProgress, cancelToken: cancelToken);
      } on DioException catch (e) {
        // The signature is only good for ~10 minutes. A download that
        // started near the end of that window (or a link that sat around
        // while the user read a dialog) comes back 403 — one fresh link and
        // one retry covers it without looping.
        final status = e.response?.statusCode;
        if (e.type == DioExceptionType.cancel || (status != 403 && status != 401)) rethrow;
        link = await BookFileApiService.getFileLink(file.fileKey);
        await _downloader.download(link.url, tmpPath, onReceiveProgress: onProgress, cancelToken: cancelToken);
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

  /// The tail of the `file_key`, stripped of anything that isn't safe in a
  /// path. The extension is forced to match `file_format` so the readers
  /// (and [OwnBooksStore]-style extension sniffing) always agree with the
  /// store entry.
  static String _safeFileName(BookFile file) {
    final tail = file.fileKey.split('/').last;
    var name = tail.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (name.isEmpty || name == '.') name = 'book';
    final ext = '.${file.fileFormat.toLowerCase()}';
    if (!name.toLowerCase().endsWith(ext)) name = '$name$ext';
    return name;
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('BookDownloadService: could not clean up $path — $e');
    }
  }
}
