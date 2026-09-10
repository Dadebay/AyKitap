import 'package:dio/dio.dart';
import '../models/revenue_cat_config.dart';
import '../models/topup_product.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import '../network/revenue_cat_endpoints.dart';
import 'revenue_cat_service.dart' show rcLog;

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
  /// [appUserId] — SDK'nın o an taşıdığı RevenueCat kimliği. Normalde bizim
  /// `user_<id>`'miz olur ve backend bunu yok sayar; ama RevenueCat'in
  /// identify çağrısı geçmediyse (Türkmenistan'da DNS engelli) SDK anonim
  /// kimlikte kalır ve satın alma o kimliğe yazılır. Backend'e bildirmek,
  /// gelen webhook'un doğru hesapla eşleşmesini sağlar ve o kimlik yüzünden
  /// daha önce eşleşmemiş event'leri yeniden işletir.
  static Future<void> reconcile({String? appUserId}) async {
    rcLog('backend: POST ${RevenueCatEndpoints.reconcile} gönderiliyor'
        '${appUserId == null ? "" : " | appUserId=$appUserId"}');
    try {
      final response = await DioClient.instance.post(
        RevenueCatEndpoints.reconcile,
        data: appUserId == null ? null : {'appUserId': appUserId},
      );
      // Backend `synced` ya da `pending` döner — `pending`, backend'in
      // RevenueCat API'sine ulaşamadığı anlamına gelir (bkz. Türkmenistan
      // DNS engeli), satın almanın başarısız olduğu anlamına gelmez.
      rcLog(
          'backend: reconcile yanıtı | ${response.data?['data'] ?? response.data}');
    } on DioException catch (e) {
      rcLog('❌ backend: reconcile hata | ${e.message}');
      throw ApiException.fromDioException(e);
    }
  }

  /// Which payment surfaces the signed-in user should see. [platform]
  /// (`'ios'` or `'android'`) is accepted only to match
  /// [PurchaseModeService]'s fetch-callback shape (and to give tests a seam)
  /// — it is deliberately never sent to the backend: `/revenuecat/config`
  /// takes no platform parameter and returns `iosStoreIapOnlyEnabled` the
  /// same way for every caller (see APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md
  /// §3.3). Prefer [PurchaseModeService] over calling this directly: it is
  /// the one place in the app that turns this response into an actual
  /// wallet-vs-store-vs-blocked decision.
  static Future<RevenueCatConfig> getConfig(String platform) async {
    try {
      final response = await DioClient.instance.get(RevenueCatEndpoints.config);
      return RevenueCatConfig.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
