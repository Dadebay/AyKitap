import 'package:aykitap/core/models/book_detail.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/services/book_recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const author = LibraryBookAuthor(id: 4, name: 'Author');
  const anotherAuthor = LibraryBookAuthor(id: 5, name: 'Other');
  const finished = BookDetail(
    id: 1,
    name: 'The Artist',
    genres: [BookDetailGenre(id: 7, name: 'Thriller')],
    authors: [author],
    languageId: 2,
  );

  test('queries the finished book category and language, skipping editions',
      () async {
    final queries = <(int, int?)>[];
    final service = BookRecommendationService(
      loadBook: (id) async {
        expect(id, 1);
        return finished;
      },
      loadGenreBooks: (genreId, languageId) async {
        queries.add((genreId, languageId));
        return const [
          LibraryBook(id: 1, name: 'The Artist', authors: [author]),
          LibraryBook(id: 2, name: 'Художник', authors: [author]),
          LibraryBook(
              id: 6,
              name: 'Suratkeş',
              authors: [LibraryBookAuthor(id: 8, name: 'Author')]),
          LibraryBook(id: 3, name: 'The Artist!', authors: [anotherAuthor]),
          LibraryBook(
              id: 4,
              name: 'Already read',
              authors: [anotherAuthor],
              progress: 100),
          LibraryBook(
              id: 5, name: 'A different thriller', authors: [anotherAuthor]),
        ];
      },
    );

    expect((await service.suggest(1))?.id, 5);
    expect(queries, [(7, 2)]);
  });

  test('tries another category when the first has no distinct book', () async {
    final queriedGenres = <int>[];
    final service = BookRecommendationService(
      loadBook: (_) async => const BookDetail(
        id: 1,
        name: 'Finished',
        authors: [author],
        genres: [
          BookDetailGenre(id: 7, name: 'Thriller'),
          BookDetailGenre(id: 9, name: 'Fiction'),
        ],
      ),
      loadGenreBooks: (genreId, languageId) async {
        queriedGenres.add(genreId);
        expect(languageId, isNull);
        return genreId == 7
            ? const [
                LibraryBook(id: 2, name: 'Translation', authors: [author])
              ]
            : const [
                LibraryBook(
                    id: 3, name: 'Other fiction', authors: [anotherAuthor])
              ];
      },
    );

    expect((await service.suggest(1))?.id, 3);
    expect(queriedGenres, [7, 9]);
  });

  test('does not offer an unverified category match', () async {
    final service = BookRecommendationService(
      loadBook: (_) async => const BookDetail(id: 1, name: 'No genre'),
      loadGenreBooks: (_, __) async =>
          fail('must not query the full catalogue'),
    );
    expect(await service.suggest(1), isNull);
  });

  test('book detail accepts language identifiers from the API', () {
    expect(
        BookDetail.fromJson({'id': 1, 'name': 'A', 'language_id': '2'})
            .languageId,
        2);
    expect(
        BookDetail.fromJson({'id': 1, 'name': 'A', 'book_language_id': 3})
            .languageId,
        3);
    expect(
        BookDetail.fromJson({
          'id': 1,
          'name': 'A',
          'language': {'id': 4}
        }).languageId,
        4);
  });
}
