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

  /// GET — no query parameters, same response for every platform.
  /// Region/currency/purchase-mode for the signed-in user
  /// ([RevenueCatConfig]), including the iOS-only App Store review toggle
  /// ([RevenueCatConfig.iosStoreIapOnlyEnabled]). See [PurchaseModeService]
  /// for how the app turns this into an actual routing decision — nothing
  /// else should call this directly.
  static const String config = '/revenuecat/config';
}
