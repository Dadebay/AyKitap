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

  const RevenueCatConfig({
    required this.appUserId,
    required this.entitlementId,
    required this.enabled,
    required this.billingRegion,
    required this.displayCurrency,
    required this.purchaseMode,
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
      );
}
