import 'package:dio/dio.dart';
import '../models/book_detail.dart';
import '../models/library_book.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the real `/books/*` endpoints — [listBooks] backs
/// [LibraryScreen]'s reading/purchased/liked tabs with real `LibraryBook`s;
/// [likeBook]/[unlikeBook] are called from [BookDetailScreen]'s favorite
/// toggle as a fire-and-forget best-effort sync (the local toggle there is
/// still the UI's actual source of truth).
///
/// [likeBook]/[unlikeBook] 404 for every *other* book in the app today:
/// Search still runs on `MockData`'s generated books, so only a
/// `LibraryBook.id` from [listBooks] is a real backend id — a mock
/// `Book.id` (`book_3_7`, ...) has no real book behind it to like.
class BookApiService {
  BookApiService._();

  /// GET `/books/all` — [myBooks]/[bought]/[wantsTo] map to the backend's
  /// `my_books`/`bought`/`wants_to` filters; only one is expected to be true
  /// per call (each is a distinct [LibraryScreen] tab). [size] is generous
  /// rather than paginated since these are all personal, naturally-small
  /// lists (what the signed-in user is reading/bought/liked), not the full
  /// catalogue.
  static Future<List<LibraryBook>> listBooks({
    bool? myBooks,
    bool? bought,
    bool? wantsTo,
    int? authorId,
    int? genreId,
    int page = 1,
    int size = 100,
  }) async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.booksAll, queryParameters: {
        'page': page,
        'size': size,
        if (myBooks == true) 'my_books': true,
        if (bought == true) 'bought': true,
        if (wantsTo == true) 'wants_to': true,
        if (authorId != null) 'author_id': authorId,
        if (genreId != null) 'genre_id': genreId,
      });
      final items = response.data['data']['items'] as List;
      return items.map((e) => LibraryBook.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET `/books/:id` — one book's full detail.
  static Future<BookDetail> getBookById(int id) async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.bookById(id));
      return BookDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/books/:bookId/like`.
  static Future<void> likeBook(String bookId) async {
    try {
      await DioClient.instance.post(ApiEndpoints.likeBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/unlike/:bookId`.
  static Future<void> unlikeBook(String bookId) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.unlikeBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/bought/:bookId`.
  ///
  /// This only removes the book from the user's purchased-library list; it
  /// deliberately does not delete the catalogue book itself.
  static Future<void> removeBoughtBook(int bookId) async {
    try {
      await DioClient.instance.delete(ApiEndpoints.removeBoughtBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
