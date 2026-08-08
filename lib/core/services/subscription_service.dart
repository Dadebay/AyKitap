import 'package:flutter/foundation.dart';
import '../network/api_exception.dart';
import 'account_service.dart';
import 'payment_api_service.dart';

/// A subscriber reads every book for free — no per-book purchase needed —
/// which is what [BookDetailScreen] and [PurchasedBooksStore] key off of.
///
/// Thin facade over [AccountService]'s `/users/me` `subscription` field
/// (`tariff_id`/`activated_at`/`expired_at` — set by `POST
/// /users/buy-subscription/:id`, [PaymentApiService.buySubscription], which
/// returns the same shape): no state of its own, just forwards
/// [AccountService]'s notifications so the existing
/// `context.watch<SubscriptionService>()` call sites (and
/// [BookAccessService], which has no [BuildContext] to watch AccountService
/// from directly) don't need to change now that the backend tracks this
/// itself instead of the app computing an expiry on-device.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._() {
    AccountService.instance.addListener(notifyListeners);
  }
  static final instance = SubscriptionService._();

  bool get isActive {
    final expiredAt = AccountService.instance.user?.subscription?.expiredAt;
    return expiredAt != null && expiredAt.isAfter(DateTime.now());
  }

  DateTime? get expiresAt {
    final expiredAt = AccountService.instance.user?.subscription?.expiredAt;
    return isActive ? expiredAt : null;
  }

  /// Ensures [AccountService] has loaded at least once — cheap to call from
  /// every screen that needs subscription status.
  Future<void> load() async {
    if (AccountService.instance.user == null) await AccountService.instance.refresh();
  }

  /// Pays for [tariffId] (`POST /users/buy-subscription/:id`, [priceManat]
  /// manat) and refreshes [AccountService] to pick up the `expired_at` the
  /// backend just set — no local date math, since the server tracks this
  /// itself.
  ///
  /// Returns false (leaving the subscription untouched) when the balance
  /// doesn't cover the price — checked client-side first to skip a
  /// guaranteed-to-fail request, and again via the backend's own 400 if
  /// the cached balance was stale — so the caller can show the
  /// insufficient-balance dialog either way. Any other failure (no
  /// connection, 500, ...) throws [ApiException] instead, since offering
  /// "top up your balance" for a problem that isn't about the balance
  /// would be misleading.
  Future<bool> subscribe({required int tariffId, required int priceManat}) async {
    if (priceManat > 0) {
      final balance = AccountService.instance.balanceManat;
      if (balance == null || balance < priceManat) return false;
    }
    try {
      await PaymentApiService.buySubscription(tariffId);
    } on ApiException catch (e) {
      if (e.statusCode == 400) return false;
      rethrow;
    }
    await AccountService.instance.refresh();
    return true;
  }
}
