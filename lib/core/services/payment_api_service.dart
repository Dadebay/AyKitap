import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/bank.dart';
import '../models/payment_order.dart';
import '../models/tariff.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the `/payments/*` endpoints behind [SubscriptionScreen]'s plan
/// list and bank-card top-up, plus `/users/buy-subscription/:id` — grouped
/// here with the rest of the payment surface despite the different prefix,
/// same reasoning as [ApiEndpoints.buyBook].
class PaymentApiService {
  PaymentApiService._();

  static Future<List<Tariff>> getTariffs() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.tariffs);
      final list = response.data['data'] as List;
      final tariffs = list.map((e) => Tariff.fromJson(e as Map<String, dynamic>)).toList();
      tariffs.sort((a, b) => a.monthCount.compareTo(b.monthCount));
      return tariffs;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Future<List<Bank>> getBanks() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.banks);
      final list = response.data['data'] as List;
      return list.map((e) => Bank.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET `/payments/my` — the signed-in user's own bank-card top-up
  /// orders, newest first.
  static Future<List<PaymentOrder>> getMyOrders() async {
    try {
      final response = await DioClient.instance.get(ApiEndpoints.paymentsMy);
      final list = response.data['data'] as List;
      final orders = list.map((e) => PaymentOrder.fromJson(e as Map<String, dynamic>)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/payments/orders` — creates a balance top-up order for [amount]
  /// manat via bank [bankId], returning the `invoiceUrl` to open in
  /// [PaymentWebViewScreen]. Throws [ApiException] if the backend didn't
  /// hand back a usable url, same as any other failure.
  static Future<String> createTopUpOrder({required int amount, required int bankId}) async {
    try {
      final response = await DioClient.instance.post(ApiEndpoints.paymentOrders, data: {
        'amount': amount,
        'bank_id': bankId,
      });
      final url = (response.data['data'] as Map<String, dynamic>?)?['invoiceUrl'];
      if (url is! String || url.isEmpty) throw const ApiException('Töleg sahypasynyň salgysy alynmady.');
      return url;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST `/users/buy-subscription/:tariffId` — pays for [tariffId] from
  /// the signed-in user's balance. Throws [ApiException] on failure (most
  /// commonly a 400 "not enough balance", whose message is shown as-is).
  static Future<void> buySubscription(int tariffId) async {
    try {
      await DioClient.instance.post(ApiEndpoints.buySubscription(tariffId));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GETs the bank's post-payment redirect (`.../payments/activate-
  /// order/:id?orderId=...`) — [PaymentWebViewScreen] catches that
  /// navigation rather than letting the WebView load it, since this is the
  /// call that actually credits the top-up to the balance (confirmed with
  /// backend, 2026-08-07 — a bank-card top-up otherwise silently never
  /// lands even though the bank shows "paid").
  ///
  /// The bank's own `return_url` (registered server-side, not something
  /// this app controls) is missing the `/api/v1` prefix the backend
  /// actually serves this under — [redirectUri]'s path segments are
  /// otherwise exactly right, so this only inserts that one segment before
  /// reissuing it. [_withApiV1Prefix] is a no-op once the backend's own
  /// `return_url` is fixed to include it, so this keeps working either way.
  ///
  /// A plain, unauthenticated request — not [DioClient] (wrong host, and
  /// would attach this app's bearer token to a URL the bank's own browser
  /// reaches with no session of its own; the `orderId` in the query string
  /// is what authorizes this instead).
  static Future<void> activateOrder(Uri redirectUri) async {
    final uri = _withApiV1Prefix(redirectUri);
    log('💳 activateOrder: $redirectUri -> $uri');
    try {
      final response = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15))).get(uri.toString());
      log('💳 activateOrder response: ${response.statusCode} ${response.data}');
    } on DioException catch (e) {
      log('💳 activateOrder DioException: ${e.type} status=${e.response?.statusCode} body=${e.response?.data} message=${e.message}');
      // Seen in practice (2026-08-07): `api.aykitap.com.tm` — the bank's
      // own return_url host — doesn't resolve on every network
      // ("Failed host lookup"), even though it's the same backend
      // [DioClient]'s configured `ApiConfig.baseUrl` (an IP, not this
      // domain) reaches fine. Retry there instead of failing outright —
      // only for a connection failure, not for a response the server
      // actually sent back (a real error there wouldn't be fixed by
      // asking a different host).
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        log('💳 activateOrder: ${uri.host} unreachable, retrying via the configured API host');
        await _activateOrderViaConfiguredHost(uri);
        return;
      }
      throw ApiException.fromDioException(e);
    }
  }

  /// Reissues the already-`/api/v1`-corrected [correctedUri] against
  /// [DioClient]'s own configured host instead of the bank's return_url
  /// domain — strips the `/api/v1` back off first since [DioClient]'s base
  /// URL already includes it.
  static Future<void> _activateOrderViaConfiguredHost(Uri correctedUri) async {
    final path = '/${correctedUri.pathSegments.skip(2).join('/')}';
    try {
      final response = await DioClient.instance.get(path, queryParameters: correctedUri.queryParameters);
      log('💳 activateOrder (fallback host) response: ${response.statusCode} ${response.data}');
    } on DioException catch (e) {
      log('💳 activateOrder (fallback host) DioException: ${e.type} status=${e.response?.statusCode} body=${e.response?.data}');
      throw ApiException.fromDioException(e);
    }
  }

  static Uri _withApiV1Prefix(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'api' && segments[1] == 'v1') return uri;
    return uri.replace(pathSegments: ['api', 'v1', ...segments]);
  }
}
