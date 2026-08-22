import 'package:dio/dio.dart';
import '../network/book_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Buying one book from the balance — `POST /users/buy-book/:id`. The
/// backend takes the money server-side; [BookPurchaseScreen] re-reads
/// `/users/me` afterwards rather than guessing at the new balance itself.
///
/// Throws [ApiException] on failure — most commonly a 400 "you do not have
/// enough balance", whose message comes straight from the backend and is
/// shown as-is.
class BookPurchaseApiService {
  BookPurchaseApiService._();

  /// POST `/users/buy-book/:bookId`. The 201 response's `data` is a
  /// presigned download link for the file just bought, unused here — the
  /// normal `/books/file` call still resolves it when the reader actually
  /// opens the book.
  static Future<void> buy(int bookId) async {
    try {
      await DioClient.instance.post(BookEndpoints.buyBook(bookId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
