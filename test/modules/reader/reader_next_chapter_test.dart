import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/modules/reader/provider/reader_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_dio_adapter.dart';

EpubChapter _chapter(String title, String href,
        {List<EpubChapter> subitems = const []}) =>
    EpubChapter(title: title, href: href, id: '', subitems: subitems);

EpubLocation _location(String tocHref) => EpubLocation(
      startCfi: 'epubcfi(/6/4)',
      endCfi: 'epubcfi(/6/4)',
      href: tocHref.split('#').first,
      tocHref: tocHref,
      progress: 0.2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StreakService.instance.resetForTest();
    FakeDioAdapter.install();
  });

  test('next chapter follows TOC anchors even within the same spine file',
      () async {
    final provider = ReaderProvider();
    await provider.initialize(bookId: 4401, bookTitle: 'Test');
    final first = _chapter('Chapter 1', 'OEBPS/all.xhtml#one');
    final second = _chapter('Chapter 2', 'OEBPS/all.xhtml#two');
    final third = _chapter('Chapter 3', 'OEBPS/end.xhtml');
    provider.onChaptersLoaded([
      _chapter('Part', 'OEBPS/part.xhtml', subitems: [first, second]),
      third,
    ]);

    provider.onRelocated(_location('all.xhtml#one'));
    expect(provider.nextChapter, same(second));
    provider.onRelocated(_location('all.xhtml#two'));
    expect(provider.nextChapter, same(third));
    expect(provider.previousChapter, same(first));
    provider.onRelocated(_location('end.xhtml'));
    expect(provider.nextChapter, isNull);

    await provider.saveAndClose();
    provider.dispose();
  });

  test('duplicate TOC hrefs are skipped instead of looping in one chapter',
      () async {
    final provider = ReaderProvider();
    await provider.initialize(bookId: 4402, bookTitle: 'Test');
    final second = _chapter('Chapter 2', 'chapters.xhtml#two');
    provider.onChaptersLoaded([
      _chapter('Part', 'chapters.xhtml#one', subitems: [
        _chapter('Chapter 1', 'chapters.xhtml#one'),
        second,
      ]),
    ]);

    provider.onRelocated(_location('chapters.xhtml#one'));
    expect(provider.nextChapter, same(second));
    provider.onRelocated(_location('chapters.xhtml#two'));
    expect(provider.nextChapter, isNull);

    await provider.saveAndClose();
    provider.dispose();
  });
}
