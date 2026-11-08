/// One row from `GET /payments/tariffs` — a subscription plan
/// [SubscriptionScreen] lists.
///
/// [dayCount] is the length that always arrives; [monthCount] only comes
/// with plans that happen to divide into whole months, and is `null` for the
/// rest. A 7-day plan is exactly that case, and reading its length out of
/// `month_count` used to throw `type 'Null' is not a subtype of type 'int'`
/// before the screen could render anything — so everything that needs a
/// length works off [lengthInDays] instead, and [monthCount] is only
/// consulted for wording.
///
/// [actualPrice], when present and higher than [price], is the pre-discount
/// reference price (shown struck through); `null` means no discount.
class Tariff {
  final int id;

  /// Length in days — `day_count`, present on every plan.
  final int dayCount;

  /// Whole months, when the plan divides into them. `null` for a plan
  /// measured in days (the weekly one), so never assume it is set.
  final int? monthCount;

  final int price;
  final int? actualPrice;

  /// Plans the backend has switched off are filtered out before they reach
  /// the screen — see [PaymentApiService.getTariffs].
  final bool isActive;

  /// The backend's own display order. Ties are broken by length, so two
  /// plans sharing a `sort_order` still come out shortest-first rather than
  /// in whatever order the response happened to list them.
  final int sortOrder;

  const Tariff({
    required this.id,
    required this.dayCount,
    this.monthCount,
    required this.price,
    this.actualPrice,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// The length to do arithmetic with. Falls back to [monthCount], and then
  /// to a month, so nothing downstream can divide by zero on a malformed row.
  int get lengthInDays {
    if (dayCount > 0) return dayCount;
    final months = monthCount;
    if (months != null && months > 0) return months * 30;
    return 30;
  }

  /// What this plan works out to per month — the figure that lets plans of
  /// different lengths be compared. Derived from [lengthInDays] rather than
  /// from [monthCount] so it is defined for the day-based plans too.
  double get pricePerMonth => price * 30 / lengthInDays;

  /// The same figure per week, for plans too short for a monthly rate to
  /// describe — see [isShorterThanAMonth].
  double get pricePerWeek => price * 7 / lengthInDays;

  /// Whether quoting this plan per month would describe money the reader
  /// never actually hands over in one go. A 7-day plan at 10 TMT works out
  /// to 42.9 a month, which next to its own 10 TMT price reads as a mistake
  /// rather than as the comparison it is — so short plans are quoted per
  /// week instead.
  bool get isShorterThanAMonth => lengthInDays < 30;

  bool get hasDiscount => actualPrice != null && actualPrice! > price;

  /// Rounded percentage saved off [actualPrice], 0 when [hasDiscount] is false.
  int get discountPercent =>
      hasDiscount ? (((actualPrice! - price) / actualPrice!) * 100).round() : 0;

  factory Tariff.fromJson(Map<String, dynamic> json) => Tariff(
        id: _asInt(json['id']) ?? 0,
        dayCount: _asInt(json['day_count']) ?? 0,
        monthCount: _asInt(json['month_count']),
        price: _asInt(json['price']) ?? 0,
        actualPrice: _asInt(json['actual_price']),
        // Absent means "no opinion", which has to read as visible: hiding a
        // plan the backend never asked to hide would quietly cost a sale.
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: _asInt(json['sort_order']) ?? 0,
      );
}

/// The plans worth showing, in the order to show them.
///
/// Switched-off plans are dropped, and the rest follow the backend's own
/// `sort_order` — that is where it says a newly added plan belongs. Length
/// breaks ties (the weekly and monthly plans currently share order 0) so the
/// list can't reshuffle between responses that happen to serialise in a
/// different order.
List<Tariff> visibleTariffsInOrder(Iterable<Tariff> tariffs) {
  final visible = tariffs.where((t) => t.isActive).toList();
  visible.sort((a, b) {
    final byOrder = a.sortOrder.compareTo(b.sortOrder);
    return byOrder != 0 ? byOrder : a.lengthInDays.compareTo(b.lengthInDays);
  });
  return visible;
}

/// Numbers from this backend arrive as ints, as doubles (`price_usd`), and
/// occasionally as numeric strings (see [LibraryBook]'s `progress` and
/// [AuthorSearchResult]'s `book_count`). Accepting all three costs nothing
/// and keeps one loose field from taking the whole plan list down with it.
int? _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return num.tryParse(raw)?.round();
  return null;
}
