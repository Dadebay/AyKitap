import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_exception.dart';
import 'account_service.dart';
import 'auth_session.dart';
import 'payment_api_service.dart';

/// A subscriber reads every book for free — no per-book purchase needed —
/// which is what [BookDetailScreen] and [PurchasedBooksStore] key off of.
///
/// Thin facade over [AccountService]'s `/users/me` `subscription` field
/// (`tariff_id`/`activated_at`/`expired_at` — set by `POST
/// /users/buy-subscription/:id`, [PaymentApiService.buySubscription], which
/// returns the same shape). Its latest server-confirmed expiry is persisted
/// locally, and it forwards [AccountService]'s notifications so the existing
/// `context.watch<SubscriptionService>()` call sites (and
/// [BookAccessService], which has no [BuildContext] to watch AccountService
/// from directly) don't need to change now that the backend tracks this
/// itself instead of the app computing an expiry on-device.
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._() {
    AccountService.instance.addListener(_onAccountChanged);
  }
  static final instance = SubscriptionService._();

  static const _kCachedUserId = 'subscription_cache_user_id_v1';
  static const _kCachedExpiry = 'subscription_cache_expiry_v1';

  DateTime? _cachedExpiry;
  bool _loaded = false;

  bool get isActive {
    final expiredAt =
        AccountService.instance.user?.subscription?.expiredAt ?? _cachedExpiry;
    return expiredAt != null && expiredAt.isAfter(DateTime.now());
  }

  DateTime? get expiresAt {
    final expiredAt =
        AccountService.instance.user?.subscription?.expiredAt ?? _cachedExpiry;
    return isActive ? expiredAt : null;
  }

  /// Loads the last server-confirmed expiry first, so access decisions remain
  /// available offline after an app restart. A fresh account response then
  /// replaces that cache whenever the network is available.
  Future<void> load() async {
    if (!_loaded) {
      await _loadCachedExpiry();
    }
    if (AccountService.instance.user == null) {
      await AccountService.instance.refresh();
    }
    await _saveAccountExpiry();
  }

  void _onAccountChanged() {
    unawaited(_saveAccountExpiry());
    notifyListeners();
  }

  Future<void> _loadCachedExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUserId = prefs.getInt(_kCachedUserId);
    final currentUserId = await AuthSession.getUserId();
    final rawExpiry = prefs.getString(_kCachedExpiry);
    _cachedExpiry = cachedUserId == currentUserId && rawExpiry != null
        ? DateTime.tryParse(rawExpiry)
        : null;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveAccountExpiry() async {
    final user = AccountService.instance.user;
    if (user == null) return; // The refresh may simply have failed offline.
    final prefs = await SharedPreferences.getInstance();
    _cachedExpiry = user.subscription?.expiredAt;
    await prefs.setInt(_kCachedUserId, user.id);
    if (_cachedExpiry == null) {
      await prefs.remove(_kCachedExpiry);
    } else {
      await prefs.setString(_kCachedExpiry, _cachedExpiry!.toIso8601String());
    }
    _loaded = true;
    notifyListeners();
  }

  /// Removes this account's subscription shadow during logout so a later
  /// account on the same device can never inherit its access.
  Future<void> clear() async {
    _cachedExpiry = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserId);
    await prefs.remove(_kCachedExpiry);
    notifyListeners();
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
  Future<bool> subscribe(
      {required int tariffId, required int priceManat}) async {
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
    await _refreshUntilActive();
    return true;
  }

  /// `buy-subscription` returning 200 doesn't always mean `/users/me`
  /// already reflects it — seen in the wild as a purchase that reports
  /// success while the app still shows no access for a few seconds, until
  /// an unrelated later refresh happens to pick up the new `expired_at`.
  /// Poll a handful of times (a few seconds total) instead of trusting the
  /// first refresh, so [isActive] is already true by the time the success
  /// dialog appears and the caller returns to the book.
  Future<void> _refreshUntilActive() async {
    const retryDelays = [
      Duration(milliseconds: 600),
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ];
    await AccountService.instance.refresh();
    for (final delay in retryDelays) {
      if (isActive) return;
      await Future.delayed(delay);
      await AccountService.instance.refresh();
    }
  }
}
