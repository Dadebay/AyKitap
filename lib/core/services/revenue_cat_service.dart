import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'auth_session.dart';
import 'revenue_cat_client.dart';

export 'revenue_cat_client.dart' show RevenueCatPurchaseException;

/// The App Store/Play Store purchase path, alongside — not replacing — the
/// bank-card/balance flow in [SubscriptionService]/`PaymentApiService`. That
/// flow stays the only way to pay by bank card or promo code; this one
/// exists for store-billed subscriptions (and any platform, like iOS, where
/// digital content must be sold through the platform's own IAP).
///
/// [isPlusActive] on its own is *not* what the rest of the app should gate
/// reading on — [PremiumAccessService] merges this with the legacy backend
/// subscription and is the single source of truth every UI call site uses.
///
/// Mirrors [OneSignalService]'s shape on purpose: [init] is meant to run
/// once at boot, [login]/[logout] queue behind it if called first (an OTP
/// login can land before `init()` resolves on a cold start), and every
/// public method swallows its own failure — a RevenueCat outage must never
/// crash the app or block a reader from opening a book they already have
/// access to.
class RevenueCatService extends ChangeNotifier {
  RevenueCatService._({RevenueCatClient? client})
      : _client = client ?? const LiveRevenueCatClient();

  static final instance = RevenueCatService._();

  /// Test seam — a service wired to a fake client, with no global state
  /// shared with [instance].
  @visibleForTesting
  factory RevenueCatService.forTest(RevenueCatClient client) =>
      RevenueCatService._(client: client);

  /// Public per RevenueCat's own model — these are the client-side public
  /// SDK keys, not the secret v2 REST API key (that one stays server-side
  /// and must never be bundled into the app). RevenueCat issues a
  /// **separate** key per store — an Apple key (`appl_...`) is a different
  /// credential from a Google key (`goog_...`) even for apps in the same
  /// RevenueCat project — so one shared key does not work for both
  /// platforms. The dashboard's public app-specific keys are safe to ship in
  /// the client. A build can still override them when rotating environments:
  /// `--dart-define=REVENUECAT_IOS_PUBLIC_KEY=appl_...
  ///  --dart-define=REVENUECAT_ANDROID_PUBLIC_KEY=goog_...`
  static const _iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_PUBLIC_KEY',
    defaultValue: 'appl_EZNHWohHbvIOMmdPPfixzVfSAVy',
  );
  static const _androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_PUBLIC_KEY',
    defaultValue: 'goog_jDtebAWwPsBLhwPceLHmsnMrCkK',
  );

  /// RevenueCat Test Store remains available for non-mobile targets and can
  /// also be selected explicitly with a dart-define during development.
  static const _devApiKey = 'test_nfXTZNsChxsiaHUDTGvlDsViFYG';

  /// Resolves to the real app-specific key on iOS/Android. Any unsupported
  /// platform falls back to Test Store; mobile release builds never do.
  static String get apiKey {
    if (Platform.isIOS && _iosApiKey.isNotEmpty) return _iosApiKey;
    if (Platform.isAndroid && _androidApiKey.isNotEmpty) {
      return _androidApiKey;
    }
    return _devApiKey;
  }

  /// Must exactly match both the RevenueCat dashboard entitlement identifier
  /// and the backend's `REVENUECAT_ENTITLEMENT_ID`. Keep this ASCII-only so a
  /// visually similar Unicode character can never silently block access.
  static const entitlementId = 'premium';

  final RevenueCatClient _client;

  bool _ready = false;
  bool get isReady => _ready;

  int? _pendingLoginUserId;
  bool _pendingLogout = false;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  /// Whether the signed-in App User ID currently has the `premium`
  /// entitlement active. See the class doc — prefer
  /// [PremiumAccessService.isPremium] at UI call sites.
  bool get isPlusActive =>
      _customerInfo?.entitlements.active.containsKey(entitlementId) ?? false;

  /// Null when there's no active entitlement, or it's a lifetime/non-expiring
  /// grant (e.g. a promotional entitlement).
  DateTime? get plusExpiresAt {
    final raw =
        _customerInfo?.entitlements.active[entitlementId]?.expirationDate;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Configures the SDK and loads the current (anonymous, until [login] is
  /// called) customer's info. Call once from `main()`, awaited — unlike
  /// [OneSignalService.initialize] this isn't fire-and-forget, because
  /// [PremiumAccessService] needs it to already reflect reality by the time
  /// the first screen that gates on it builds.
  Future<void> init() async {
    if (_ready) return;
    try {
      await _client.configure(apiKey, debugLogging: kDebugMode);
      _client.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      _customerInfo = await _client.getCustomerInfo();
      _ready = true;
      notifyListeners();
      await _flushPending();
    } catch (error) {
      // No app id/network at boot must never crash startup — the reader
      // just won't see Plus-gated content until the SDK comes back.
      debugPrint('RevenueCat init failed | $error');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _customerInfo = info;
    notifyListeners();
  }

  /// Re-binds whatever session is already on the device. Called at boot,
  /// after [init], so a returning user's purchases attach to their backend
  /// account id rather than staying on the anonymous device id RevenueCat
  /// assigns by default.
  Future<void> loginCurrentUser() async {
    final userId = await AuthSession.getUserId();
    if (userId != null) await login(userId);
  }

  /// The backend's numeric account id is the only identifier used here —
  /// same rule as [OneSignalService.externalIdFor]: never the phone number,
  /// bearer token or device fingerprint, since this id is visible in the
  /// RevenueCat dashboard.
  static String appUserIdFor(int userId) => 'user_$userId';

  Future<void> login(int userId) async {
    if (!_ready) {
      _pendingLoginUserId = userId;
      _pendingLogout = false;
      return;
    }
    await _applyLogin(userId);
  }

  /// Detaches the current App User ID and hands the device a fresh
  /// anonymous one — call on logout so a second account signing in on the
  /// same device never inherits the first one's purchases.
  Future<void> logout() async {
    if (!_ready) {
      _pendingLogout = true;
      _pendingLoginUserId = null;
      return;
    }
    await _applyLogout();
  }

  Future<void> _flushPending() async {
    if (_pendingLogout) {
      _pendingLogout = false;
      await _applyLogout();
    } else if (_pendingLoginUserId != null) {
      final userId = _pendingLoginUserId!;
      _pendingLoginUserId = null;
      await _applyLogin(userId);
    }
  }

  Future<void> _applyLogin(int userId) async {
    try {
      _customerInfo = await _client.logIn(appUserIdFor(userId));
      notifyListeners();
    } catch (error) {
      debugPrint('RevenueCat login failed | $error');
    }
  }

  Future<void> _applyLogout() async {
    try {
      _customerInfo = await _client.logOut();
      notifyListeners();
    } catch (error) {
      debugPrint('RevenueCat logout failed | $error');
    }
  }

  /// Best-effort re-sync — e.g. after returning from the system subscription
  /// management page, where a change wouldn't otherwise reach this app until
  /// the next [_onCustomerInfoUpdated] push.
  Future<void> refreshCustomerInfo() async {
    try {
      _customerInfo = await _client.getCustomerInfo();
      notifyListeners();
    } catch (error) {
      debugPrint('RevenueCat refreshCustomerInfo failed | $error');
    }
  }

  /// The dashboard's current offering — its `availablePackages` are what a
  /// custom (non-paywall-template) plan-picker UI would list. Null on
  /// failure (no network, SDK not configured yet, no offering configured).
  Future<Offerings?> getOfferings() async {
    try {
      return await _client.getOfferings();
    } catch (error) {
      debugPrint('RevenueCat getOfferings failed | $error');
      return null;
    }
  }

  /// Matched by [PackageType] rather than a hardcoded product id — the
  /// dashboard's `default` offering attaches each store subscription to a
  /// package using RevenueCat's predefined $rc_monthly/$rc_annual
  /// identifiers, and [PackageType] reflects *that* regardless of what the
  /// underlying store product id happens to be. That id is platform-
  /// specific and not "monthly"/"yearly" literally (e.g.
  /// `aykitap_pro_month` on iOS, `aykitap_monthly:monthly` on Android), so
  /// matching against it directly would never find a package on either
  /// platform.
  Future<Package?> monthlyPackage() async =>
      _packageForType(await getOfferings(), PackageType.monthly);

  Future<Package?> yearlyPackage() async =>
      _packageForType(await getOfferings(), PackageType.annual);

  Package? _packageForType(Offerings? offerings, PackageType type) {
    final packages = offerings?.current?.availablePackages;
    if (packages == null) return null;
    for (final package in packages) {
      if (package.packageType == type) return package;
    }
    return null;
  }

  /// Buys [package] directly — for a custom plan-picker UI that isn't using
  /// [presentPaywall]. Returns null when the user cancels (not an error);
  /// any other failure throws [RevenueCatPurchaseException] for the caller
  /// to show a message for.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    final info = await _client.purchasePackage(package);
    if (info != null) {
      _customerInfo = info;
      notifyListeners();
    }
    return info;
  }

  /// Re-links this device's store purchase history to the current App User
  /// ID — the "Restore purchases" action every store review guideline
  /// requires be reachable without contacting support.
  Future<CustomerInfo?> restorePurchases() async {
    final info = await _client.restorePurchases();
    _customerInfo = info;
    notifyListeners();
    return info;
  }

  /// Presents the dashboard-configured paywall unconditionally. Prefer
  /// [presentPaywallIfNeeded] for an entry point a Plus subscriber can also
  /// reach (e.g. a settings tile) — this one is for a button that only
  /// exists to sell Plus in the first place.
  Future<PaywallResult> presentPaywall({Offering? offering}) async {
    try {
      final result = await _client.presentPaywall(offering: offering);
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        await refreshCustomerInfo();
      }
      return result;
    } catch (error) {
      debugPrint('RevenueCat presentPaywall failed | $error');
      return PaywallResult.error;
    }
  }

  /// Presents the paywall only if the current customer does *not* already
  /// have [entitlementId] active — returns [PaywallResult.notPresented]
  /// instead of showing it again to an existing subscriber.
  Future<PaywallResult> presentPaywallIfNeeded({Offering? offering}) async {
    try {
      final result = await _client.presentPaywallIfNeeded(entitlementId,
          offering: offering);
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        await refreshCustomerInfo();
      }
      return result;
    } catch (error) {
      debugPrint('RevenueCat presentPaywallIfNeeded failed | $error');
      return PaywallResult.error;
    }
  }

  /// Presents RevenueCat's native Customer Center — self-serve
  /// cancel/manage/refund-request/FAQ, configured in the dashboard rather
  /// than built here. Refreshes [customerInfo] afterwards since the user
  /// may have cancelled or changed plans while it was open.
  Future<void> presentCustomerCenter() async {
    try {
      await _client.presentCustomerCenter();
      await refreshCustomerInfo();
    } catch (error) {
      debugPrint('RevenueCat presentCustomerCenter failed | $error');
    }
  }
}
