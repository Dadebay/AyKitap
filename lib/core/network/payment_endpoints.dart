/// Subscription/bank-payment endpoints — [PaymentApiService],
/// [SubscriptionScreen], [PaymentWebViewScreen]. Split out of the former
/// single `api_endpoints.dart` by which service owns each route. Paths are
/// relative to [ApiConfig.baseUrl].
class PaymentEndpoints {
  PaymentEndpoints._();

  /// GET — the subscription tariffs (`month_count`/`price`/`actual_price`)
  /// [SubscriptionScreen] lists as plans.
  static const String tariffs = '/payments/tariffs';

  /// POST — buys tariff [tariffId] for the signed-in user, paying from the
  /// balance. Same shape as [BookEndpoints.buyBook]: 201 on success (money
  /// moved server-side), 400 `{"message": "You do not have enough
  /// balance", ...}` when it doesn't cover the price. What this actually
  /// *grants* — the active-until date — isn't in this response or
  /// `/users/me` yet, so [SubscriptionService] still tracks that on-device.
  static String buySubscription(int tariffId) =>
      '/users/buy-subscription/$tariffId';

  /// GET — banks offered for card payment, shown in the bank-selection
  /// sheet before checkout.
  static const String banks = '/payments/banks';

  /// POST `{amount, bank_id}` — creates a balance top-up order. 201's
  /// `data.invoiceUrl` is the bank's online payment page
  /// ([PaymentWebViewScreen] opens it in-app); the balance itself only
  /// moves once the bank confirms the payment server-side, so the caller
  /// re-reads `/users/me` after the webview closes rather than trusting
  /// anything client-side. This is the *only* bank-card money-in path —
  /// there is no separate "pay for this subscription/book via bank"
  /// endpoint; [buySubscription]/[BookPurchaseApiService.buy] both spend
  /// from whatever balance this has put there.
  static const String paymentOrders = '/payments/orders';

  /// GET — the signed-in user's own bank-card top-up orders, newest first
  /// (each with its bank and amount) — [BalanceScreen]'s "card payments"
  /// section.
  static const String paymentsMy = '/payments/my';
}
