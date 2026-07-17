import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/stable_hash.dart';

/// Where CbzReaderScreen extracts a CBZ's pages to, keyed by the source
/// file's own path. Shared with [deleteCbzPageCache] so a removed book's
/// extraction — otherwise never cleaned up — doesn't linger on disk forever.
Future<Directory> cbzPageCacheDirFor(String filePath) async {
  final dir = await getApplicationSupportDirectory();
  final key = stableBookKey(filePath).toRadixString(16);
  return Directory('${dir.path}/cbz_pages/$key');
}

/// Deletes [filePath]'s extraction cache, if any. Safe to call for a book
/// that was never opened (nothing was ever extracted) or isn't a CBZ at all.
Future<void> deleteCbzPageCache(String filePath) async {
  try {
    final dir = await cbzPageCacheDirFor(filePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {}
}
