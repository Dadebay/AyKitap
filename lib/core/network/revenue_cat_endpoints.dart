/// RevenueCat-related backend endpoints — [RevenueCatApiService]. Paths are
/// relative to [ApiConfig.baseUrl].
class RevenueCatEndpoints {
  RevenueCatEndpoints._();

  /// GET `?platform=ios|android` — the wallet top-up denominations
  /// purchasable through the store on this platform ([TopupProduct]s),
  /// cheapest first. Public/no auth — catalog data, not user-specific.
  static const String topupProducts = '/revenuecat/topup-products';

  /// POST — re-syncs the signed-in user's local premium/purchase state
  /// against whatever RevenueCat's own REST API currently says. Called
  /// right after a store purchase so the balance/entitlement reflects it
  /// immediately rather than waiting on the webhook's own delivery.
  static const String reconcile = '/revenuecat/reconcile';

  /// GET — region/currency/purchase-mode for the signed-in user
  /// ([RevenueCatConfig]). The balance top-up sheet uses
  /// [RevenueCatConfig.isStoreIap] to decide whether to offer the
  /// store/card option alongside promo code and bank card.
  static const String config = '/revenuecat/config';
}
