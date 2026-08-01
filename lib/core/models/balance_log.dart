/// One balance movement from `GET /users/balance-logs`.
class BalanceLog {
  final int id;
  final DateTime createdAt;
  final int amount;
  final String event;
  final String? promoCode;
  final int? bookId;
  final String? bookName;

  const BalanceLog({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.event,
    this.promoCode,
    this.bookId,
    this.bookName,
  });

  factory BalanceLog.fromJson(Map<String, dynamic> json) => BalanceLog(
        id: json['id'] as int,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        event: json['event'] as String? ?? '',
        promoCode: json['promo_code'] as String?,
        bookId: json['book_id'] as int?,
        bookName: json['book_name'] as String?,
      );

  /// The API's purchase event name is intentionally treated flexibly so a
  /// renamed server enum still renders correctly as a debit in the app.
  bool get isBookPurchase {
    final normalized = event.toUpperCase();
    return bookId != null ||
        bookName != null ||
        normalized.contains('BOOK') ||
        normalized.contains('PURCHASE');
  }

  bool get isCredit => !isBookPurchase && amount >= 0;
}
