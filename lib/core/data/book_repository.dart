import '../models/book.dart';

/// Everything a screen needs to fetch books/authors/collections/series
/// through, instead of reaching into a concrete data source directly.
/// [MockBookRepository] is the only implementation today; swapping in a
/// real backend later means writing an `ApiBookRepository` that implements
/// this same contract — no screen has to change.
abstract interface class BookRepository {
  List<HomeSection> homeSections();
  List<Book> booksForSection({required int seed, int count = 15});
  List<Book> popularBooks();
  List<BookCollection> collections();
  List<BookSeries> series();
  List<Author> authors();

  /// The seeded mock catalogue generator itself, for screens that need an
  /// ad-hoc slice (a given count/seed pair) rather than one of the named
  /// queries above.
  List<Book> generateBooks(int count, {int seed});
}
