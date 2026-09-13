import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Web and unsupported platforms keep the package's normal cache storage.
FileSystem createCoverImageCacheFileSystem(String _) => MemoryCacheSystem();
