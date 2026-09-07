/// The response of `GET /revenuecat/config` — [RevenueCatApiService.getConfig].
/// Tells the client which payment surfaces the signed-in user should see: a
/// Turkmenistan phone/country resolves to [purchaseMode] `wallet` (promo
/// code + bank card only); everyone else resolves to `store_iap` once
/// RevenueCat is enabled for foreign billing. A blank country does not block
/// a non-`+993` Firebase account from using the store path.
class RevenueCatConfig {
  final String appUserId;
  final String entitlementId;
  final bool enabled;
  final String billingRegion;
  final String displayCurrency;
  final String purchaseMode;

  /// iOS-only App Store review setting — see
  /// APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md. When `true`, iOS must sell
  /// everything (subscriptions, wallet top-ups, and never a single-book
  /// purchase) through App Store/RevenueCat only, regardless of
  /// [billingRegion] or [purchaseMode] — see [PurchaseModeService].
  /// Android never reads this field. Defaults to `true` (the backend's own
  /// migration default, and the safe assumption on a response from a
  /// backend that hasn't shipped the field yet).
  final bool iosStoreIapOnlyEnabled;

  const RevenueCatConfig({
    required this.appUserId,
    required this.entitlementId,
    required this.enabled,
    required this.billingRegion,
    required this.displayCurrency,
    required this.purchaseMode,
    this.iosStoreIapOnlyEnabled = true,
  });

  /// Whether the store (RevenueCat) payment surface should be offered at
  /// all — [enabled] on its own isn't enough, since a TM wallet user
  /// shouldn't see a store option just because RevenueCat happens to be
  /// turned on for foreign users.
  bool get isStoreIap => enabled && purchaseMode == 'store_iap';

  factory RevenueCatConfig.fromJson(Map<String, dynamic> json) =>
      RevenueCatConfig(
        appUserId: json['appUserId'] as String,
        entitlementId: json['entitlementId'] as String,
        enabled: json['enabled'] as bool,
        billingRegion: json['billingRegion'] as String,
        displayCurrency: json['displayCurrency'] as String,
        purchaseMode: json['purchaseMode'] as String,
        iosStoreIapOnlyEnabled: json['iosStoreIapOnlyEnabled'] as bool? ?? true,
      );
}
