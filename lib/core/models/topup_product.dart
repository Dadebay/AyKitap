/// One row from `GET /revenuecat/topup-products` — a wallet top-up
/// denomination purchasable through the App/Play Store on this platform.
/// [productId] is the store product id [RevenueCatService] looks up in the
/// current offering's packages; [topupAmount] is the TMT amount it credits
/// once the purchase is confirmed (set by the backend admin, not the
/// store's own charged price — see StoreProduct.topup_amount on the
/// backend).
class TopupProduct {
  final int id;
  final String productId;
  final int topupAmount;

  const TopupProduct({
    required this.id,
    required this.productId,
    required this.topupAmount,
  });

  factory TopupProduct.fromJson(Map<String, dynamic> json) => TopupProduct(
        id: json['id'] as int,
        productId: json['product_id'] as String,
        topupAmount: json['topup_amount'] as int,
      );
}
