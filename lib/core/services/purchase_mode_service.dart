import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/revenue_cat_config.dart';
import 'revenue_cat_api_service.dart';

/// The single source of truth for "which payment surfaces can this user
/// see right now" — see APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md. Every screen
/// that used to call [RevenueCatApiService.getConfig] directly
/// ([openSubscriptionScreen], `startBalanceTopUp`, [BalanceScreen]) reads
/// its routing decision from here instead, so the iOS-only App Store review
/// rule lives in exactly one place rather than being re-derived — and
/// potentially re-derived *inconsistently* — in each of them.
///
/// [isIOSStoreOnly] is the iOS-only override: while it's `true`, a payment
/// surface must sell only through App Store/RevenueCat — never wallet,
/// promo code, bank card, or a single-book purchase — regardless of what
/// [isRegionStoreIap] says. It starts `true` (the backend's own migration
/// default) and *stays* `true` on any fetch failure: an admin toggle flip
/// mid-review or a dropped connection must never quietly reopen the paths
/// Apple rejected on a build already submitted or live. Android never
/// consults this at all — [isIOSStoreOnly] is hardcoded `false` there, so
/// every Android call site keeps exactly its pre-existing behaviour.
///
/// [isRegionStoreIap] is the existing Turkmenistan-wallet-vs-foreign-store
/// region decision, unchanged — the answer for Android always, and for iOS
/// only once [isIOSStoreOnly] has been proven `false` by a real config
/// response.
class PurchaseModeService extends ChangeNotifier with WidgetsBindingObserver {
  PurchaseModeService._({
    bool Function()? isIOS,
    Future<RevenueCatConfig> Function(String platform)? fetchConfig,
  })  : _isIOS = isIOS ?? (() => Platform.isIOS),
        _fetchConfig = fetchConfig ?? RevenueCatApiService.getConfig;

  static final instance = PurchaseModeService._();

  /// Test seam — a service with an injected platform and config fetcher, no
  /// global state shared with [instance], and no [WidgetsBinding] observer
  /// registered (call [refresh] directly instead of [init] in a test).
  @visibleForTesting
  factory PurchaseModeService.forTest({
    required bool isIOS,
    required Future<RevenueCatConfig> Function(String platform) fetchConfig,
  }) =>
      PurchaseModeService._(isIOS: () => isIOS, fetchConfig: fetchConfig);

  final bool Function() _isIOS;
  final Future<RevenueCatConfig> Function(String platform) _fetchConfig;

  bool _started = false;
  RevenueCatConfig? _config;
  bool _iosStoreOnly = true;

  /// True only on iOS, and only cleared once a successful [refresh] proves
  /// the admin toggle is off. Every iOS-only payment surface should gate on
  /// this instead of resolving [RevenueCatConfig] itself.
  bool get isIOSStoreOnly => _isIOS() && _iosStoreOnly;

  /// The pre-existing region/billing decision, for whoever [isIOSStoreOnly]
  /// doesn't already answer for: Android always, and iOS once its toggle is
  /// off. `false` (wallet) until the first successful [refresh] — the same
  /// fail-closed-to-wallet default every direct `getConfig` call site used
  /// to have on its own error handling.
  bool get isRegionStoreIap => _config?.isStoreIap ?? false;

  /// Whichever payment surface should actually be used right now — the one
  /// check most call sites want instead of combining the two getters
  /// themselves.
  bool get useStoreCheckout => isIOSStoreOnly || isRegionStoreIap;

  /// Registers the app-lifecycle listener and fires the first [refresh].
  /// Call once from [AppBootstrapService]; safe to call again (a no-op)
  /// from anywhere that isn't sure it already ran.
  void init() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  // Refreshing on every foreground return, not just app boot, is what lets
  // an admin's toggle flip apply to an already-installed app without a new
  // binary — see the plan's §5.4 requirement.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// Re-fetches the config for the running platform. Never throws — a
  /// failure on iOS is handled by staying store-only (see class doc); a
  /// failure on Android leaves [isRegionStoreIap] at its last-known value
  /// (or its `false` default), matching every direct `getConfig` call
  /// site's original `catch (_) { return false; }`.
  Future<void> refresh() async {
    final platform = _isIOS() ? 'ios' : 'android';
    try {
      final config = await _fetchConfig(platform);
      _config = config;
      if (_isIOS()) _iosStoreOnly = config.iosStoreIapOnlyEnabled;
    } catch (_) {
      if (_isIOS()) _iosStoreOnly = true;
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    if (_started) WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _config = null;
    _iosStoreOnly = true;
  }
}
