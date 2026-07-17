import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../utils/stable_hash.dart';

/// Temporary bridge that lets any mock [Book] "open" in the real EPUB reader
/// for testing, before the backend serves per-book files. It maps a book onto
/// one of the sample EPUBs bundled in `assets/books/` and copies it into
/// app-owned storage (the reader needs a real filesystem path — the package's
/// [EpubSource.fromFile], not an asset key).
class SampleBookStore {
  SampleBookStore._();

  static List<String>? _epubAssets;

  /// Bundled `assets/books/*.epub` keys, discovered once from the asset
  /// manifest and sorted so the book→file mapping stays stable across runs.
  static Future<List<String>> _assets() async {
    if (_epubAssets != null) return _epubAssets!;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    _epubAssets = manifest
        .listAssets()
        .where((k) => k.startsWith('assets/books/') && k.toLowerCase().endsWith('.epub'))
        .toList()
      ..sort();
    return _epubAssets!;
  }

  /// Copies the sample EPUB mapped to [book] into a cached file and returns
  /// its path, ready to hand to `ReaderScreen`. The copy is done once per
  /// asset — later opens reuse the cached file.
  static Future<String> epubPathFor(Book book) async {
    final assets = await _assets();
    if (assets.isEmpty) {
      throw StateError('No sample EPUBs bundled under assets/books/');
    }
    final assetKey = assets[stableBookKey(book.id) % assets.length];
    final fileName = assetKey.split('/').last;

    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/sample_books');
    if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

    final dest = File('${cacheDir.path}/$fileName');
    if (!await dest.exists()) {
      final data = await rootBundle.load(assetKey);
      await dest.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    }
    return dest.path;
  }
}
