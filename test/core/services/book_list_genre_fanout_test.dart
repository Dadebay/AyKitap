// Regression cover for multi-genre search: `GET /books/all`'s `genre_id` is
// single-valued on the backend, so picking more than one genre chip has to
// fan out into one request per genre and merge the responses — the same
// pattern already proven for language/format — rather than either silently
// dropping every genre but one or sending something the backend ignores.
import 'package:aykitap/core/network/book_endpoints.dart';
import 'package:aykitap/core/services/book_list_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two selected genres fire one request each and merge, deduplicated',
      () async {
    final adapter = FakeDioAdapter.install();

    final books =
        await BookListApiService.listBooks(genreIds: {1, 2}, size: 10);

    final requests =
        adapter.requests.where((r) => r.path == BookEndpoints.booksAll);
    expect(requests.length, 2);
    expect(
      requests.map((r) => r.queryParameters['genre_id']).toSet(),
      {1, 2},
    );

    // Genre 1 -> books {1, 3}, genre 2 -> books {2, 3}: merged is {1, 2, 3},
    // not four entries with 3 twice.
    expect(books.map((b) => b.id).toSet(), {1, 2, 3});
    expect(books.length, 3);
  });

  test('a single selected genre makes exactly one plain request', () async {
    final adapter = FakeDioAdapter.install();

    await BookListApiService.listBooks(genreIds: {1}, size: 10);

    final requests =
        adapter.requests.where((r) => r.path == BookEndpoints.booksAll);
    expect(requests.length, 1);
    expect(requests.single.queryParameters['genre_id'], 1);
  });

  test('no genre selected omits `genre_id` entirely', () async {
    final adapter = FakeDioAdapter.install();

    await BookListApiService.listBooks(size: 10);

    final requests =
        adapter.requests.where((r) => r.path == BookEndpoints.booksAll);
    expect(requests.length, 1);
    expect(requests.single.queryParameters.containsKey('genre_id'), isFalse);
  });
}
