import 'package:flutter/foundation.dart';

import 'revenue_cat_service.dart';
import 'subscription_service.dart';

/// Which system actually grants the reader's current premium access —
/// surfaced for debugging/analytics and the profile screen, not for gating
/// (that's [PremiumAccessService.isPremium]).
enum PremiumSource {
  /// Neither system has an active grant.
  none,

  /// Only the legacy backend subscription (bank card / promo code / Manat
  /// balance, [SubscriptionService]) is active.
  wallet,

  /// Only the RevenueCat store entitlement ([RevenueCatService]) is active.
  store,

  /// Both are active at once — e.g. a wallet subscriber who also bought the
  /// store subscription on another device signed into the same account.
  both,
}

/// Merges the two independent premium signals this app has — the legacy
/// backend-driven [SubscriptionService] (bank card / promo code / Manat
/// balance) and the store-driven [RevenueCatService] (`premium`
/// entitlement) — into the single `isPremium`/`expiresAt`/`source` API every
/// "does this reader have Plus" call site should use instead of picking one
/// system and forgetting the other exists.
///
/// [BookAccessService.resolve]/[BookAccessService.canRead] are the actual
/// call sites; nothing downstream of those needs to know two systems exist
/// underneath. The merge itself is a plain OR / latest-expiry — exposed as
/// [computeIsPremium]/[computeExpiresAt] static functions so that logic is
/// testable without standing up either real singleton.
class PremiumAccessService extends ChangeNotifier {
  PremiumAccessService._() {
    SubscriptionService.instance.addListener(notifyListeners);
    RevenueCatService.instance.addListener(notifyListeners);
  }

  static final instance = PremiumAccessService._();

  bool get isPremium => computeIsPremium(
        walletActive: SubscriptionService.instance.isActive,
        storeActive: RevenueCatService.instance.isPlusActive,
      );

  DateTime? get expiresAt => computeExpiresAt(
        walletExpiresAt: SubscriptionService.instance.expiresAt,
        storeExpiresAt: RevenueCatService.instance.isPlusActive
            ? RevenueCatService.instance.plusExpiresAt
            : null,
      );

  PremiumSource get source {
    final wallet = SubscriptionService.instance.isActive;
    final store = RevenueCatService.instance.isPlusActive;
    if (wallet && store) return PremiumSource.both;
    if (wallet) return PremiumSource.wallet;
    if (store) return PremiumSource.store;
    return PremiumSource.none;
  }

  @visibleForTesting
  static bool computeIsPremium(
          {required bool walletActive, required bool storeActive}) =>
      walletActive || storeActive;

  /// The later of the two expiries — a reader shouldn't lose access on
  /// whichever side happens to expire first while the other is still valid.
  @visibleForTesting
  static DateTime? computeExpiresAt(
      {DateTime? walletExpiresAt, DateTime? storeExpiresAt}) {
    if (walletExpiresAt == null) return storeExpiresAt;
    if (storeExpiresAt == null) return walletExpiresAt;
    return walletExpiresAt.isAfter(storeExpiresAt)
        ? walletExpiresAt
        : storeExpiresAt;
  }
}
