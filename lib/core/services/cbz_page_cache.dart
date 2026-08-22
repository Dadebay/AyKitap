import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
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

/// Each extracted page's width/height ratio, in page order — what the reader's
/// continuous scroll mode needs to know how tall every page will be before it
/// builds them (see CbzScrollMetrics).
///
/// Reads only each image's header rather than decoding the picture, so a
/// few-hundred-page book costs milliseconds, not a full decode pass. The
/// result is cached next to the extracted pages, keyed by page count so a
/// re-extraction that changes the count recomputes instead of serving stale
/// heights. A page whose header can't be read yields 0, which
/// CbzScrollMetrics treats as "use the fallback ratio".
Future<List<double>> cbzPageAspectRatios({
  required String filePath,
  required List<String> pagePaths,
}) async {
  File? cacheFile;
  try {
    final dir = await cbzPageCacheDirFor(filePath);
    cacheFile = File('${dir.path}/aspect_ratios.json');
    if (await cacheFile.exists()) {
      final decoded =
          jsonDecode(await cacheFile.readAsString()) as List<dynamic>;
      if (decoded.length == pagePaths.length) {
        return decoded
            .map((e) => (e as num).toDouble())
            .toList(growable: false);
      }
    }
  } catch (_) {
    // Unreadable/corrupt cache — fall through and recompute.
  }

  final ratios = <double>[];
  for (final path in pagePaths) {
    ratios.add(await _aspectRatioOf(path));
  }
  try {
    await cacheFile?.writeAsString(jsonEncode(ratios), flush: true);
  } catch (_) {}
  return ratios;
}

/// width / height for the image at [path], or 0 if it can't be read.
Future<double> _aspectRatioOf(String path) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  try {
    buffer = await ui.ImmutableBuffer.fromFilePath(path);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    return (width > 0 && height > 0) ? width / height : 0;
  } catch (_) {
    return 0;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// Deletes [filePath]'s extraction cache, if any. Safe to call for a book
/// that was never opened (nothing was ever extracted) or isn't a CBZ at all.
Future<void> deleteCbzPageCache(String filePath) async {
  try {
    final dir = await cbzPageCacheDirFor(filePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (_) {}
}
