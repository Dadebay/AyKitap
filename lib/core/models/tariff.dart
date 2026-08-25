/// One row from `GET /payments/tariffs` — a subscription plan
/// [SubscriptionScreen] lists. [actualPrice], when present and higher than
/// [price], is the pre-discount reference price (shown struck through);
/// `null` means this tariff has no discount.
class Tariff {
  final int id;
  final int monthCount;
  final int price;
  final int? actualPrice;

  const Tariff({
    required this.id,
    required this.monthCount,
    required this.price,
    this.actualPrice,
  });

  bool get hasDiscount => actualPrice != null && actualPrice! > price;

  /// Rounded percentage saved off [actualPrice], 0 when [hasDiscount] is false.
  int get discountPercent =>
      hasDiscount ? (((actualPrice! - price) / actualPrice!) * 100).round() : 0;

  factory Tariff.fromJson(Map<String, dynamic> json) => Tariff(
        id: json['id'] as int,
        monthCount: json['month_count'] as int,
        price: json['price'] as int,
        actualPrice: json['actual_price'] as int?,
      );
}
