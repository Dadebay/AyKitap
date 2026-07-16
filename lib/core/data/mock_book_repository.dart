import '../models/book.dart';
import 'book_repository.dart';
import 'mock/mock_data.dart';

/// The only [BookRepository] this app has today — delegates every query
/// straight to [MockData]. Screens that inject/read a [BookRepository]
/// (rather than calling `MockData` directly) are the ones that'll need no
/// changes at all once a real `ApiBookRepository` replaces this.
class MockBookRepository implements BookRepository {
  @override
  List<HomeSection> homeSections() => MockData.homeSections;

  @override
  List<Book> booksForSection({required int seed, int count = 15}) => MockData.generateBooks(count, seed: seed);

  @override
  List<Book> popularBooks() => MockData.generateBooks(15, seed: 99);

  @override
  List<BookCollection> collections() => MockData.collections;

  @override
  List<BookSeries> series() => MockData.series;

  @override
  List<Author> authors() => MockData.authors;

  @override
  List<Book> generateBooks(int count, {int seed = 0}) => MockData.generateBooks(count, seed: seed);
}
