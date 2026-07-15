import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_service.dart';

/// The 4 subscription lengths offered on [SubscriptionScreen], with the
/// business rules (price, duration) that used to live only in the UI layer.
enum SubscriptionPlanType { weekly, monthly, threeMonths, sixMonths }

extension SubscriptionPlanMeta on SubscriptionPlanType {
  int get priceManat {
    switch (this) {
      case SubscriptionPlanType.weekly:
        return 10;
      case SubscriptionPlanType.monthly:
        return 25;
      case SubscriptionPlanType.threeMonths:
        return 70;
      case SubscriptionPlanType.sixMonths:
        return 135;
    }
  }

  Duration get duration {
    switch (this) {
      case SubscriptionPlanType.weekly:
        return const Duration(days: 7);
      case SubscriptionPlanType.monthly:
        return const Duration(days: 30);
      case SubscriptionPlanType.threeMonths:
        return const Duration(days: 90);
      case SubscriptionPlanType.sixMonths:
        return const Duration(days: 180);
    }
  }
}

/// Local stand-in for server-tracked subscription state (TZ §13.1 / §10.2).
/// A subscriber reads every book for free — no per-book purchase needed —
/// which is what [BookDetailScreen] and [PurchasedBooksStore] key off of.
/// Buying a plan debits the same on-device balance [StreakService] manages.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const _kExpiresAt = 'subscription_expires_at_v1';
  static const _kPlan = 'subscription_plan_v1';

  DateTime? _expiresAt;
  SubscriptionPlanType? _plan;
  bool _loaded = false;

  bool get isActive => _expiresAt != null && _expiresAt!.isAfter(DateTime.now());
  SubscriptionPlanType? get activePlan => isActive ? _plan : null;
  DateTime? get expiresAt => isActive ? _expiresAt : null;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawExpiry = prefs.getString(_kExpiresAt);
    _expiresAt = rawExpiry != null ? DateTime.tryParse(rawExpiry) : null;
    final rawPlan = prefs.getString(_kPlan);
    for (final p in SubscriptionPlanType.values) {
      if (p.name == rawPlan) _plan = p;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Debits [plan]'s price from the balance and activates it. Renewing while
  /// already active extends from the current expiry rather than from now.
  /// Returns false (leaving the subscription untouched) if the balance is short.
  Future<bool> subscribe(SubscriptionPlanType plan) async {
    await load();
    final ok = await StreakService.instance.spendBalance(plan.priceManat);
    if (!ok) return false;

    final base = isActive ? _expiresAt! : DateTime.now();
    _expiresAt = base.add(plan.duration);
    _plan = plan;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExpiresAt, _expiresAt!.toIso8601String());
    await prefs.setString(_kPlan, plan.name);
    return true;
  }
}
