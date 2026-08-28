import 'package:dio/dio.dart';
import '../models/revenue_cat_config.dart';
import '../models/topup_product.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import '../network/revenue_cat_endpoints.dart';

/// The backend-HTTP half of the RevenueCat integration — [RevenueCatService]
/// itself only talks to the store SDK. Kept separate the same way
/// [PaymentApiService] is split from [SubscriptionService].
class RevenueCatApiService {
  RevenueCatApiService._();

  static Future<List<TopupProduct>> getTopupProducts(String platform) async {
    try {
      final response = await DioClient.instance.get(
        RevenueCatEndpoints.topupProducts,
        queryParameters: {'platform': platform},
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => TopupProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Best-effort — a failure here just means the balance shows the old
  /// number until the webhook lands on its own; callers should never treat
  /// this throwing as the purchase itself having failed.
  static Future<void> reconcile() async {
    try {
      await DioClient.instance.post(RevenueCatEndpoints.reconcile);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Which payment surfaces the signed-in user should see. The balance
  /// top-up sheet calls this before showing [PaymentMethodSheet] so it can
  /// decide whether to add the store/card option alongside the always-on
  /// promo-code and bank-card ones.
  static Future<RevenueCatConfig> getConfig() async {
    try {
      final response = await DioClient.instance.get(RevenueCatEndpoints.config);
      return RevenueCatConfig.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
