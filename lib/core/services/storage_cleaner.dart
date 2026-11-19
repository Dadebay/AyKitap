import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/stable_hash.dart';
import 'book_download_service.dart';
import 'cover_image_cache_manager.dart';
import 'downloaded_files_store.dart';
import 'own_books_store.dart';

/// Frees the space books leave behind on the device.
///
/// Deleting a book removes its file and the caches derived from *that exact
/// path* ([DownloadedFilesStore.removeBook]). That misses anything whose
/// owner is no longer known: a book folder left by an interrupted download
/// or a replaced format, a CBZ extraction or PDF reflow keyed by a path that
/// no longer exists (app update/reinstall moves the app's folder on iOS),
/// and reflow caches written by older converter versions. [sweepOrphans]
/// deletes all of that by comparing what is on disk with what the library
/// still owns, so "Data" in the system storage settings really drops.
class StorageCleaner {
  StorageCleaner._();

  /// Must match the folder [PdfReflowService] currently writes to
  /// (`pdf_reflow/v4/...`); every other version folder is stale.
  static const _currentReflowVersion = 'v4';

  /// Bytes the book-related folders occupy right now.
  static Future<int> usedBytes() async {
    final support = await getApplicationSupportDirectory();
    var total = 0;
    for (final name in const ['books', 'cbz_pages', 'pdf_reflow']) {
      total += await _dirSize(Directory('${support.path}/$name'));
    }
    return total;
  }

  /// Deletes book data nothing in the library refers to. Returns the bytes
  /// freed. Never throws; does nothing while a download is running (its
  /// half-written file would look like an orphan).
  static Future<int> sweepOrphans() async {
    try {
      if (BookDownloadService.instance.hasActiveDownloads) return 0;
      await DownloadedFilesStore.instance.load();
      await OwnBooksStore.instance.load();
      final support = await getApplicationSupportDirectory();

      final entries = DownloadedFilesStore.instance.entries;
      final ownedIds = entries.map((e) => e.bookId).toSet();
      final ownedFiles = entries.map((e) => e.path).toSet();
      final cacheKeys = {
        ...entries.map((e) => stableBookKey(e.path).toRadixString(16)),
        ...OwnBooksStore.instance.books
            .map((b) => stableBookKey(b.filePath).toRadixString(16)),
      };

      var freed = 0;

      // books/<id>/ — whole folders of books no longer downloaded, and
      // stray files (.tmp, an old format) inside folders that still are.
      final books = Directory('${support.path}/books');
      if (await books.exists()) {
        await for (final item in books.list()) {
          final name = item.uri.pathSegments.where((s) => s.isNotEmpty).last;
          if (item is! Directory) continue; // keep books/.nomedia
          final id = int.tryParse(name);
          if (id == null) continue;
          if (!ownedIds.contains(id)) {
            freed += await _deleteDir(item);
            continue;
          }
          await for (final inner in item.list(recursive: true)) {
            if (inner is File && !ownedFiles.contains(inner.path)) {
              freed += await _deleteFile(inner);
            }
          }
        }
      }

      // cbz_pages/<key>/ — extractions of books that are gone.
      freed += await _deleteUnkeyed(
          Directory('${support.path}/cbz_pages'), cacheKeys);

      // pdf_reflow/<version>/<key>/ — old converter versions entirely, and
      // the current one for books that are gone.
      final reflow = Directory('${support.path}/pdf_reflow');
      if (await reflow.exists()) {
        await for (final version in reflow.list()) {
          if (version is! Directory) continue;
          final name = version.uri.pathSegments.where((s) => s.isNotEmpty).last;
          if (name != _currentReflowVersion) {
            freed += await _deleteDir(version);
          } else {
            freed += await _deleteUnkeyed(version, cacheKeys);
          }
        }
      }

      if (kDebugMode && freed > 0) {
        debugPrint(
            '🧹 StorageCleaner: freed ${_mb(freed)} of orphaned book data');
      }
      return freed;
    } catch (e) {
      if (kDebugMode) debugPrint('🧹 StorageCleaner failed: $e');
      return 0;
    }
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  static Future<int> _deleteUnkeyed(Directory root, Set<String> keep) async {
    if (!await root.exists()) return 0;
    var freed = 0;
    await for (final item in root.list()) {
      if (item is! Directory) continue;
      final key = item.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (!keep.contains(key)) freed += await _deleteDir(item);
    }
    return freed;
  }

  static Future<int> _deleteDir(Directory dir) async {
    final size = await _dirSize(dir);
    try {
      await dir.delete(recursive: true);
      return size;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> _deleteFile(File file) async {
    try {
      final size = await file.length();
      await file.delete();
      return size;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    try {
      await for (final item in dir.list(recursive: true)) {
        if (item is File) total += await item.length();
      }
    } catch (_) {}
    return total;
  }

  // ── Cache (Android "Cache", iOS temporary files) ────────────────────────

  /// Bytes in the OS cache folder plus the catalogue cover cache — everything
  /// [clearCaches] removes.
  static Future<int> cacheBytes() async {
    final tmp = await getTemporaryDirectory();
    final support = await getApplicationSupportDirectory();
    return await _dirSize(tmp) +
        await _dirSize(
            Directory('${support.path}/${CoverImageCacheManager.cacheKey}'));
  }

  /// Empties every cache the app can rebuild: the OS cache folder (web view,
  /// network images, temp files), the in-memory image cache and the cover
  /// cache. Books, notes and progress are untouched. Returns the bytes freed.
  static Future<int> clearCaches() async {
    final before = await cacheBytes();
    try {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      await CoverImageCacheManager.instance.emptyCache();
      await DefaultCacheManager().emptyCache();
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) {
        await for (final item in tmp.list()) {
          try {
            await item.delete(recursive: true);
          } catch (_) {
            // A file in use right now stays; the rest still goes.
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🧹 clearCaches failed: $e');
    }
    final freed = before - await cacheBytes();
    if (kDebugMode) {
      debugPrint('🧹 clearCaches: freed ${_mb(freed < 0 ? 0 : freed)}');
    }
    return freed < 0 ? 0 : freed;
  }
}
