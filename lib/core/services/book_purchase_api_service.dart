import 'package:dio/dio.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Buying one book from the balance.
///
/// UNCONFIRMED CONTRACT — the backend has only ever shown us
/// `DELETE /books/bought/:id` (remove from the purchased library); there is
/// no capture of the purchase call, so [ApiEndpoints.buyBook] is that
/// path's POST mirror. Everything about the purchase lives behind this one
/// function on purpose: when the real endpoint (and its body/response) is
/// confirmed, this file and that one endpoint line are all that change.
///
/// [buy] reports whether the *server* recorded the purchase.
/// [BookPurchaseScreen] uses that to decide whether the balance can be
/// re-read from `/users/me` (server-side debit) or has to be adjusted
/// locally as a stand-in — see [PurchaseResult].
class BookPurchaseApiService {
  BookPurchaseApiService._();

  /// POST `/books/bought/:bookId`.
  ///
  /// Returns [PurchaseResult.serverConfirmed] on success, and
  /// [PurchaseResult.endpointMissing] when the backend answers "no such
  /// route" (404/405/501) — i.e. the guessed path above is wrong and the
  /// purchase endpoint simply isn't live yet. Any other failure (402
  /// insufficient funds, 409 already bought, no connection) throws
  /// [ApiException] so the screen can show the backend's own message.
  static Future<PurchaseResult> buy(int bookId) async {
    try {
      await DioClient.instance.post(ApiEndpoints.buyBook(bookId));
      return PurchaseResult.serverConfirmed;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 405 || status == 501) {
        return PurchaseResult.endpointMissing;
      }
      throw ApiException.fromDioException(e);
    }
  }
}

enum PurchaseResult {
  /// The backend took the money and recorded the purchase.
  serverConfirmed,

  /// No purchase route on the backend yet. The app falls back to recording
  /// the purchase on-device (and debiting the cached balance) so the read
  /// flow still works end to end — but that is a stand-in, not a real
  /// transaction: the next `/users/me` restores the untouched balance.
  endpointMissing,
}
