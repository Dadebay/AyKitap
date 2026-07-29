import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_service.dart';

/// Local stand-in for server-tracked subscription state (TZ §13.1 / §10.2).
/// A subscriber reads every book for free — no per-book purchase needed —
/// which is what [BookDetailScreen] and [PurchasedBooksStore] key off of.
/// Buying a plan debits [AccountService.balanceManat] — the same balance
/// shown on Profile/[BalanceScreen] — so a purchase only ever succeeds when
/// the user's *actual displayed* balance covers the price; there's no
/// separate on-device number the check could pass against instead.
///
/// The plan itself (price, length) comes from a real `Tariff`
/// ([PaymentApiService.getTariffs]) — this just tracks which one is active
/// and until when, entirely on-device since there's no real purchase/
/// checkout endpoint yet.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  static const _kExpiresAt = 'subscription_expires_at_v1';
  static const _kPlanMonths = 'subscription_plan_months_v1';

  DateTime? _expiresAt;
  int? _planMonthCount;
  bool _loaded = false;

  bool get isActive => _expiresAt != null && _expiresAt!.isAfter(DateTime.now());
  int? get activePlanMonthCount => isActive ? _planMonthCount : null;
  DateTime? get expiresAt => isActive ? _expiresAt : null;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawExpiry = prefs.getString(_kExpiresAt);
    _expiresAt = rawExpiry != null ? DateTime.tryParse(rawExpiry) : null;
    _planMonthCount = prefs.getInt(_kPlanMonths);
    _loaded = true;
    notifyListeners();
  }

  /// Debits [priceManat] from [AccountService.balanceManat] and activates a
  /// [monthCount]-month subscription (30 days per month). Renewing while
  /// already active extends from the current expiry rather than from now.
  /// Returns false (leaving both the balance and the subscription untouched)
  /// if that balance doesn't cover the price — the caller then shows the
  /// insufficient-balance dialog instead of silently activating.
  Future<bool> subscribe({required int monthCount, required int priceManat}) async {
    await load();
    if (priceManat > 0) {
      final balance = AccountService.instance.balanceManat;
      if (balance == null || balance < priceManat) return false;
      AccountService.instance.debitBalance(priceManat);
    }

    final base = isActive ? _expiresAt! : DateTime.now();
    _expiresAt = base.add(Duration(days: monthCount * 30));
    _planMonthCount = monthCount;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kExpiresAt, _expiresAt!.toIso8601String());
    await prefs.setInt(_kPlanMonths, monthCount);
    return true;
  }
}
