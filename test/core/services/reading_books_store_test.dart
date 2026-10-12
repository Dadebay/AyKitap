import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/services/reading_books_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = ReadingBooksStore.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store.resetForTest();
  });

  tearDown(store.resetForTest);

  test('keeps a locally opened book until backend progress exists', () async {
    const opened = LibraryBook(id: 478, name: 'The art of spending money');

    await store.recordOpened(opened);
    await store.mergeFromBackend(const []);

    expect(store.books.map((book) => book.id), [478]);
  });

  test('finished backend row removes stale local reading entry', () async {
    const opened = LibraryBook(id: 478, name: 'The art of spending money');
    const finished = LibraryBook(
      id: 478,
      name: 'The art of spending money',
      progress: 100,
    );

    await store.recordOpened(opened);
    await store.mergeFromBackend(const [finished]);

    expect(store.books, isEmpty);
  });
}
