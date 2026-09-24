import 'package:dio/dio.dart';
import '../network/book_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Buying one book from the balance — `POST /users/buy-book/:bookFileId`.
/// The backend takes the money server-side; [BookPurchaseScreen] re-reads
/// `/users/me` afterwards rather than guessing at the new balance itself.
///
/// The path segment is a **book file** id (`bookFiles[].id` off
/// `GET /books/:id`), not the book's own id. They are separate id spaces that
/// overlap, which is why sending the book id did not fail loudly: buying book
/// 188 credited book 187, whose file happened to be numbered 188. Confirmed
/// with the backend developer 21.09.2026.
///
/// Throws [ApiException] on failure — most commonly a 400 "you do not have
/// enough balance", whose message comes straight from the backend and is
/// shown as-is.
class BookPurchaseApiService {
  BookPurchaseApiService._();

  /// POST `/users/buy-book/:bookFileId`. The 201 response's `data` is a
  /// presigned download link for the file just bought, unused here — the
  /// normal `/books/file` call still resolves it when the reader actually
  /// opens the book.
  static Future<void> buy(int bookFileId) async {
    try {
      await DioClient.instance.post(BookEndpoints.buyBook(bookFileId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
