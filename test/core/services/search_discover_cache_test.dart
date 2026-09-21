// The Search page's offline placeholder. Reported as "the genres at the top
// disappear, they come back if I restart" — the chip row answered a failed
// request by emptying itself, so the row stayed blank for the whole session
// and a restart was simply another chance for the request to succeed.
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/models/genre.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/services/search_discover_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Genre> _genres(Iterable<int> ids) =>
    [for (final id in ids) Genre(id: id, name: 'Žanr $id')];

List<LibraryBook> _books(Iterable<int> ids) =>
    [for (final id in ids) LibraryBook(id: id, name: 'Kitap $id')];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('genres', () {
    test('survive a round trip with their fields intact', () async {
      await SearchDiscoverCache.writeGenres(AppLanguageCode.tk, [
        const Genre(id: 4, name: 'Roman', parentId: 1, position: 2),
      ]);

      final cached = await SearchDiscoverCache.readGenres(AppLanguageCode.tk);

      expect(cached, hasLength(1));
      expect(cached!.single.id, 4);
      expect(cached.single.name, 'Roman');
      expect(cached.single.parentId, 1);
      expect(cached.single.position, 2);
    });

    test('are kept per language, not shared across them', () async {
      // The names are translated server-side, so one shared entry would show
      // the previous language's chips after a switch.
      await SearchDiscoverCache.writeGenres(
          AppLanguageCode.tk, [const Genre(id: 1, name: 'Hekaýa')]);
      await SearchDiscoverCache.writeGenres(
          AppLanguageCode.ru, [const Genre(id: 1, name: 'Рассказ')]);

      expect(
          (await SearchDiscoverCache.readGenres(AppLanguageCode.tk))!
              .single
              .name,
          'Hekaýa');
      expect(
          (await SearchDiscoverCache.readGenres(AppLanguageCode.ru))!
              .single
              .name,
          'Рассказ');
    });

    test('read back as null for a language never cached', () async {
      await SearchDiscoverCache.writeGenres(AppLanguageCode.tk, _genres([1]));

      // Null rather than an empty list: the caller has to be able to tell
      // "nothing cached" from "cached, and the answer really was empty",
      // because only the first means "leave whatever is on screen alone".
      expect(await SearchDiscoverCache.readGenres(AppLanguageCode.en), isNull);
    });
  });

  group('discover books', () {
    test('survive a round trip in order', () async {
      await SearchDiscoverCache.writeBooks(_books([3, 1, 2]));

      final cached = await SearchDiscoverCache.readBooks();

      expect(cached?.map((b) => b.id).toList(), [3, 1, 2]);
      expect(cached?.first.name, 'Kitap 3');
    });

    test('a write replaces the previous entry rather than merging into it',
        () async {
      await SearchDiscoverCache.writeBooks(_books([1, 2, 3]));

      // The server's first page is the authority on what still exists: a book
      // it stopped returning has to disappear from the cache too, or a
      // deleted book would outlive it on every cold open.
      await SearchDiscoverCache.writeBooks(_books([2, 4]));

      expect((await SearchDiscoverCache.readBooks())?.map((b) => b.id).toList(),
          [2, 4]);
    });

    test('read back as null before anything has been cached', () async {
      expect(await SearchDiscoverCache.readBooks(), isNull);
    });

    test('an empty response leaves nothing to draw', () async {
      await SearchDiscoverCache.writeBooks(const []);

      // Reads back as null, not as an empty list — the screen treats both the
      // same way (keep the shimmer/whatever is up), and this keeps the
      // "nothing usable cached" answer to a single shape.
      expect(await SearchDiscoverCache.readBooks(), isNull);
    });
  });
}
