import 'dart:io';
import 'dart:typed_data';

import 'package:sakura_epub/src/epub_data_loader.dart';

/// Epub file source
class EpubSource {
  final Future<Uint8List> Function() _loadData;
  Future<Uint8List>? _cachedData;
  final String? filePath;

  EpubSource._({required Future<Uint8List> Function() loadData, this.filePath})
      : _loadData = loadData;

  /// Only materialize bytes for sources that cannot be read from a file.
  Future<Uint8List> get epubData => _cachedData ??= _loadData();

  ///Loading from a file
  factory EpubSource.fromFile(File file) {
    final loader = FileEpubLoader(file);
    return EpubSource._(loadData: loader.loadData, filePath: file.path);
  }

  ///load from a url with optional headers
  factory EpubSource.fromUrl(String url, {Map<String, String>? headers}) {
    final loader = UrlEpubLoader(url, headers: headers);
    return EpubSource._(loadData: loader.loadData);
  }

  ///load from assets
  factory EpubSource.fromAsset(String assetPath) {
    final loader = AssetEpubLoader(assetPath);
    return EpubSource._(loadData: loader.loadData);
  }
}
