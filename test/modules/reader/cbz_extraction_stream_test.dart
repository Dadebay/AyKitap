import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aykitap/modules/reader/utils/cbz_extraction.dart';

void main() {
  test('extracts naturally ordered pages from a file stream and reuses cache',
      () async {
    final dir = await Directory.systemTemp.createTemp('aykitap-cbz-test-');
    try {
      final archive = Archive()
        ..addFile(ArchiveFile('page10.jpg', 3, [10, 10, 10]))
        ..addFile(ArchiveFile('page2.jpg', 2, [2, 2]))
        ..addFile(ArchiveFile('readme.txt', 1, [0]));
      final zip = File('${dir.path}/book.cbz');
      await zip.writeAsBytes(ZipEncoder().encodeBytes(archive));
      final cache = '${dir.path}/pages';
      final (pages, noImages) = await runCbzExtraction((zip.path, cache));
      expect(noImages, isFalse);
      expect(pages.map((p) => p.split('/').last), ['00000.jpg', '00001.jpg']);
      expect(await File(pages.first).readAsBytes(), [2, 2]);
      expect(await File(pages.last).readAsBytes(), [10, 10, 10]);
      final (cached, _) = await runCbzExtraction((zip.path, cache));
      expect(cached, pages);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
