import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Stores covers outside the OS-managed temporary directory so closing the
/// app (or routine temp cleanup) cannot discard the catalogue image cache.
class _PersistentCoverImageFileSystem implements FileSystem {
  _PersistentCoverImageFileSystem(this.key);

  final String key;
  Future<Directory>? _directory;

  Future<Directory> _getDirectory() => _directory ??= () async {
        final support = await getApplicationSupportDirectory();
        const local = LocalFileSystem();
        final directory = local.directory(path.join(support.path, key));
        await directory.create(recursive: true);
        return directory;
      }();

  @override
  Future<File> createFile(String name) async {
    var directory = await _getDirectory();
    if (!await directory.exists()) {
      // The app's data may have been cleared while this singleton remained
      // alive. Recreate the directory before handing CacheManager a file.
      _directory = null;
      directory = await _getDirectory();
    }
    return directory.childFile(name);
  }
}

FileSystem createCoverImageCacheFileSystem(String key) =>
    _PersistentCoverImageFileSystem(key);
