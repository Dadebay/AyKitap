import '../models/book_detail.dart';
import '../models/library_book.dart';
import 'book_api_service.dart';
import 'book_list_api_service.dart';

/// Recommends an unread book from a category of the book just finished.
/// The detail endpoint supplies the actual genre; Home's promotional
/// collections do not represent book categories.
class BookRecommendationService {
  BookRecommendationService({
    Future<BookDetail> Function(int)? loadBook,
    Future<List<LibraryBook>> Function(int, int?)? loadGenreBooks,
  })  : _loadBook = loadBook ?? BookApiService.getBookById,
        _loadGenreBooks = loadGenreBooks ?? _fetchGenreBooks;

  static final instance = BookRecommendationService();

  final Future<BookDetail> Function(int) _loadBook;
  final Future<List<LibraryBook>> Function(int, int?) _loadGenreBooks;

  static Future<List<LibraryBook>> _fetchGenreBooks(
      int genreId, int? languageId) {
    return BookListApiService.listBooks(
      genreIds: [genreId],
      languageIds: languageId == null ? const [] : [languageId],
      size: 40,
    );
  }

  Future<LibraryBook?> suggest(int finishedBookId) async {
    final finished = await _loadBook(finishedBookId);
    for (final genre in finished.genres) {
      final candidates = await _loadGenreBooks(genre.id, finished.languageId);
      final recommendation = _pickDifferentBook(finished, candidates);
      if (recommendation != null) return recommendation;
    }
    // No verified category match is better than another edition of the same
    // book or a random promotional title.
    return null;
  }

  static LibraryBook? _pickDifferentBook(
      BookDetail finished, List<LibraryBook> candidates) {
    final authorIds =
        finished.authors.map((a) => a.id).where((id) => id > 0).toSet();
    final authorNames = finished.authors
        .map((a) => _normaliseTitle(a.name))
        .where((name) => name.isNotEmpty)
        .toSet();
    final finishedName = _normaliseTitle(finished.name);
    for (final book in candidates) {
      if (book.id == finished.id || book.isFinished) continue;
      if (_normaliseTitle(book.name) == finishedName) continue;
      // The same author's translated edition often has a completely
      // different title. Category matches from another author are safer.
      if ((authorIds.isNotEmpty || authorNames.isNotEmpty) &&
          (book.authors.isEmpty ||
              book.authors.any((author) =>
                  authorIds.contains(author.id) ||
                  authorNames.contains(_normaliseTitle(author.name))))) {
        continue;
      }
      return book;
    }
    return null;
  }

  static String _normaliseTitle(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');
}
