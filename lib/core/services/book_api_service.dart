import 'package:dio/dio.dart';
import '../models/book_detail.dart';
import '../network/book_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the real `/books/*` endpoints — book listing/search lives in
/// [BookListApiService] (split out to keep this file under the 200-line
/// limit); this file covers single-book detail, reading-progress sync, and
/// the favorite/purchase toggles. [likeBook]/[unlikeBook] are called from
/// [BookDetailScreen]'s favorite toggle as a fire-and-forget best-effort
/// sync (the local toggle there is still the UI's actual source of truth).
///
/// [likeBook]/[unlikeBook] 404 for any book id that *didn't* come from
/// [BookListApiService.listBooks]/[getBookById] — Home's non-collection
/// sections still show `MockData`'s generated books in places this hasn't
/// reached yet, and a mock `Book.id` (`book_3_7`, ...) has no real book
/// behind it to like.
class BookApiService {
  BookApiService._();

  /// GET `/books/:id` — one book's full detail.
  static Future<BookDetail> getBookById(int id) async {
    try {
      final response = await DioClient.instance.get(BookEndpoints.bookById(id));
      return BookDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/books/:bookId/progress` — syncs reading progress (0..100)
  /// server-side. [CatalogBookDetailScreen]'s "mark as finished" flag
  /// sends 100, same fire-and-forget best-effort shape as [likeBook].
  static Future<void> updateProgress(int bookId,
      {required int progress}) async {
    try {
      await DioClient.instance.post(BookEndpoints.bookProgress(bookId),
          data: {'progress': progress});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/:bookId/progress` — drops the signed-in user's reading
  /// progress for the book, removing it from the reading shelf and, if it
  /// was marked complete, from the finished shelf too (both shelves read the
  /// same record — see [BookEndpoints.bookProgress]). The catalogue book and
  /// any purchase of it are untouched.
  static Future<void> deleteProgress(int bookId) async {
    try {
      await DioClient.instance.delete(BookEndpoints.bookProgress(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/books/:bookId/like`.
  static Future<void> likeBook(String bookId) async {
    try {
      await DioClient.instance.post(BookEndpoints.likeBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE `/books/unlike/:bookId`.
  static Future<void> unlikeBook(String bookId) async {
    try {
      await DioClient.instance.delete(BookEndpoints.unlikeBook(bookId));
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
      await DioClient.instance.delete(BookEndpoints.removeBoughtBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
