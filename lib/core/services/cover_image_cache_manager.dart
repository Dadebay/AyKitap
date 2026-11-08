import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'cover_image_cache_file_system.dart';

/// Process-wide disk cache for public catalogue imagery.
///
/// The package default keeps only 200 files under the OS temporary directory.
/// A real catalogue can exceed that on Home alone, so covers that appeared
/// cached during one run were often missing after the in-memory cache vanished
/// on the next launch. This cache has catalogue-sized LRU capacity and uses
/// application support storage on mobile/desktop.
class CoverImageCacheManager extends CacheManager with ImageCacheManager {
  CoverImageCacheManager._()
      : super(
          Config(
            cacheKey,
            stalePeriod: const Duration(days: 180),
            maxNrOfCacheObjects: 1000,
            fileSystem: createCoverImageCacheFileSystem(cacheKey),
            fileService: _CoverImageFileService(),
          ),
        );

  static const cacheKey = 'aykitapCoverImagesV1';
  static final instance = CoverImageCacheManager._();
}

/// Public media uploads get timestamped object names, so a URL identifies an
/// immutable cover. Keep successful responses fresh for at least 30 days even
/// when a proxy omits cache headers (or supplies an overly short lifetime).
class _CoverImageFileService extends FileService {
  _CoverImageFileService() : _delegate = HttpFileService();

  final HttpFileService _delegate;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await _delegate.get(url, headers: headers);
    return _CoverImageFileResponse(response);
  }
}

class _CoverImageFileResponse implements FileServiceResponse {
  _CoverImageFileResponse(this._delegate)
      : validTill = _longerOf(
          _delegate.validTill,
          DateTime.now().add(const Duration(days: 30)),
        );

  final FileServiceResponse _delegate;

  @override
  final DateTime validTill;

  @override
  Stream<List<int>> get content => _delegate.content;

  @override
  int? get contentLength => _delegate.contentLength;

  @override
  String? get eTag => _delegate.eTag;

  @override
  String get fileExtension => _delegate.fileExtension;

  @override
  int get statusCode => _delegate.statusCode;

  static DateTime _longerOf(DateTime first, DateTime second) =>
      first.isAfter(second) ? first : second;
}
