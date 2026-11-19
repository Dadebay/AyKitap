import '../models/collection.dart';
import '../models/library_book.dart';

/// Picks a nearby unread book from catalogue data already loaded for Home.
/// No new backend route or model is required.
abstract final class BookRecommendationService {
  static LibraryBook? suggest({
    required int finishedBookId,
    required List<Collection> collections,
    List<LibraryBook> downloaded = const [],
  }) {
    final books = <int, LibraryBook>{};
    final scores = <int, int>{};
    final source = <LibraryBook>[...downloaded];
    for (final collection in collections) {
      source.addAll(collection.books);
    }
    LibraryBook? finished;
    for (final book in source) {
      books.putIfAbsent(book.id, () => book);
      if (book.id == finishedBookId) finished = book;
    }
    var order = 0;
    for (final collection in collections) {
      final related = collection.books.any((b) => b.id == finishedBookId);
      for (final book in collection.books) {
        if (book.id == finishedBookId || book.isFinished) continue;
        scores[book.id] = (scores[book.id] ?? (100 - order.clamp(0, 99))) +
            (related ? 200 : 0);
        order++;
      }
    }
    final authorIds = finished?.authors.map((a) => a.id).toSet() ?? {};
    for (final book in source) {
      if (book.id == finishedBookId || book.isFinished) continue;
      scores.putIfAbsent(book.id, () => 1);
      if (authorIds.isNotEmpty &&
          book.authors.any((a) => authorIds.contains(a.id))) {
        scores[book.id] = scores[book.id]! + 1000;
      }
    }
    if (scores.isEmpty) return null;
    final best =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return books[best];
  }
}
