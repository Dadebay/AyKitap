import 'package:flutter_test/flutter_test.dart';
import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/services/book_recommendation_service.dart';

void main() {
  const author = LibraryBookAuthor(id: 4, name: 'Author');
  const finished = LibraryBook(id: 1, name: 'Finished', authors: [author]);
  const sameAuthor = LibraryBook(id: 2, name: 'Same author', authors: [author]);
  const popular = LibraryBook(id: 3, name: 'Popular');
  const alreadyRead = LibraryBook(id: 4, name: 'Read', progress: 100);

  test('prefers the same author and excludes completed books', () {
    final recommendation = BookRecommendationService.suggest(
      finishedBookId: finished.id,
      collections: const [
        Collection(
            id: 1,
            type: CollectionType.book,
            cardType: CollectionCardType.card1,
            name: 'Shelf',
            books: [popular, finished, alreadyRead, sameAuthor]),
      ],
    );
    expect(recommendation?.id, sameAuthor.id);
  });

  test('uses downloaded titles when catalogue is unavailable', () {
    final recommendation = BookRecommendationService.suggest(
      finishedBookId: finished.id,
      collections: const [],
      downloaded: const [finished, sameAuthor],
    );
    expect(recommendation?.id, sameAuthor.id);
  });
}
