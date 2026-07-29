import 'package:dio/dio.dart';
import '../models/bank.dart';
import '../models/tariff.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';

/// Talks to the `/payments/*` endpoints behind [SubscriptionScreen]'s plan
/// list and bank-card checkout.
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

  /// See [ApiEndpoints.subscribeInitiate] — UNCONFIRMED endpoint. Tries a
  /// few likely response field names for the payment URL so a reasonable
  /// backend shape still works without a code change; returns null if none
  /// match, which the caller surfaces as [PaymentStrings.paymentUrlError].
  static Future<String?> initiateSubscriptionPayment({required int tariffId, required int bankId}) async {
    try {
      final response = await DioClient.instance.post(ApiEndpoints.subscribeInitiate, data: {
        'tariff_id': tariffId,
        'bank_id': bankId,
      });
      final data = response.data['data'];
      if (data is String) return data;
      if (data is Map) {
        final url = data['payment_url'] ?? data['paymentUrl'] ?? data['url'] ?? data['invoiceUrl'];
        return url is String ? url : null;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
