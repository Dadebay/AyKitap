import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Thrown by [RevenueCatClient.purchasePackage] and
/// [RevenueCatClient.restorePurchases] for any failure other than the user
/// cancelling — cancellation returns `null` instead (see each method), since
/// it isn't an error the UI should show a message for. Carries [code] so
/// callers can special-case things like
/// [PurchasesErrorCode.productAlreadyPurchasedError] or
/// [PurchasesErrorCode.paymentPendingError] instead of showing a generic
/// error for every failure.
class RevenueCatPurchaseException implements Exception {
  const RevenueCatPurchaseException(this.code, this.message);

  final PurchasesErrorCode code;
  final String? message;

  @override
  String toString() => 'RevenueCatPurchaseException($code, $message)';
}

/// Seam over `purchases_flutter`/`purchases_ui_flutter`'s static SDK calls —
/// same reasoning as [OneSignalClient]/[FirebaseAuthClient]: the real SDKs
/// reach for a platform channel, which throws under `flutter test`, so
/// routing through an interface is what makes [RevenueCatService] (identity
/// queueing, `isPlusActive` derivation, pending-login flush) testable with a
/// fake instead of only being exercisable on a real device.
abstract class RevenueCatClient {
  Future<void> configure(String apiKey, {required bool debugLogging});

  /// Registers [listener] for out-of-band `CustomerInfo` pushes — e.g. a
  /// renewal or cancellation the SDK learns about without this app asking.
  void addCustomerInfoUpdateListener(void Function(CustomerInfo info) listener);

  Future<CustomerInfo> getCustomerInfo();

  /// Returns the customer info for [appUserId] after binding to it —
  /// discards the SDK's `created` flag, which nothing here needs.
  Future<CustomerInfo> logIn(String appUserId);

  Future<CustomerInfo> logOut();

  /// Null on failure (no network, SDK not configured, no offering
  /// configured) rather than throwing — every caller already treats "no
  /// offering" as a normal, handleable state.
  Future<Offerings?> getOfferings();

  /// Null when the user cancels (not an error). Throws
  /// [RevenueCatPurchaseException] for any other failure.
  Future<CustomerInfo?> purchasePackage(Package package);

  /// Throws [RevenueCatPurchaseException] on failure.
  Future<CustomerInfo> restorePurchases();

  Future<PaywallResult> presentPaywall({Offering? offering});

  Future<PaywallResult> presentPaywallIfNeeded(String entitlementId,
      {Offering? offering});

  Future<void> presentCustomerCenter();
}

/// The real SDK. Every method here is a straight pass-through plus error
/// mapping — anything with a decision in it belongs in [RevenueCatService].
class LiveRevenueCatClient implements RevenueCatClient {
  const LiveRevenueCatClient();

  @override
  Future<void> configure(String apiKey, {required bool debugLogging}) async {
    await Purchases.setLogLevel(debugLogging ? LogLevel.debug : LogLevel.info);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  @override
  void addCustomerInfoUpdateListener(
      void Function(CustomerInfo info) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  @override
  Future<CustomerInfo> logIn(String appUserId) async {
    final result = await Purchases.logIn(appUserId);
    return result.customerInfo;
  }

  @override
  Future<CustomerInfo> logOut() => Purchases.logOut();

  @override
  Future<Offerings?> getOfferings() => Purchases.getOfferings();

  @override
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      throw RevenueCatPurchaseException(code, error.message);
    }
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } on PlatformException catch (error) {
      throw RevenueCatPurchaseException(
          PurchasesErrorHelper.getErrorCode(error), error.message);
    }
  }

  @override
  Future<PaywallResult> presentPaywall({Offering? offering}) =>
      RevenueCatUI.presentPaywall(offering: offering);

  @override
  Future<PaywallResult> presentPaywallIfNeeded(String entitlementId,
          {Offering? offering}) =>
      RevenueCatUI.presentPaywallIfNeeded(entitlementId, offering: offering);

  @override
  Future<void> presentCustomerCenter() => RevenueCatUI.presentCustomerCenter();
}
