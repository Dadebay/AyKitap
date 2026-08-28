import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:aykitap/core/localization/strings/settings_strings.dart';
import 'package:aykitap/core/services/revenue_cat_client.dart';
import 'package:aykitap/core/services/revenue_cat_service.dart';
import 'package:aykitap/core/theme/theme_controller.dart';
import 'package:aykitap/modules/profile/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

CustomerInfo _customerInfo({Map<String, EntitlementInfo> active = const {}}) {
  return CustomerInfo(
    EntitlementInfos({...active}, active),
    const {},
    const [],
    const [],
    const [],
    '2024-01-01T00:00:00Z',
    'anonymous',
    const {},
    '2024-01-01T00:00:00Z',
  );
}

EntitlementInfo _entitlement() => EntitlementInfo(
      RevenueCatService.entitlementId,
      true,
      true,
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'aykitap_pro_month',
      false,
    );

/// Only the surface [SettingsScreen]'s store-subscription tile exercises.
class _FakeClient implements RevenueCatClient {
  CustomerInfo info = _customerInfo();
  PaywallResult paywallResult = PaywallResult.notPresented;
  int presentCustomerCenterCount = 0;

  @override
  Future<void> configure(String apiKey, {required bool debugLogging}) async {}

  @override
  void addCustomerInfoUpdateListener(
      void Function(CustomerInfo info) listener) {}

  @override
  Future<CustomerInfo> getCustomerInfo() async => info;

  @override
  Future<CustomerInfo> logIn(String appUserId) async => info;

  @override
  Future<CustomerInfo> logOut() async => info;

  @override
  Future<Offerings?> getOfferings() async => null;

  @override
  Future<CustomerInfo?> purchasePackage(Package package) async => info;

  @override
  Future<CustomerInfo> restorePurchases() async => info;

  @override
  Future<PaywallResult> presentPaywall({Offering? offering}) async =>
      paywallResult;

  @override
  Future<PaywallResult> presentPaywallIfNeeded(String entitlementId,
          {Offering? offering}) async =>
      paywallResult;

  @override
  Future<void> presentCustomerCenter() async {
    presentCustomerCenterCount++;
  }
}

Widget _app(RevenueCatService revenueCat) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>.value(value: AppTheme.instance),
        ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
        ChangeNotifierProvider<RevenueCatService>.value(value: revenueCat),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a purchased result shows the unlock dialog once',
      (tester) async {
    final client = _FakeClient()..paywallResult = PaywallResult.purchased;
    final service = RevenueCatService.forTest(client);
    await service.init();

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    // The entitlement comes back active by the time the post-purchase
    // refresh inside presentPaywallIfNeeded reads it.
    client.info = _customerInfo(
        active: {RevenueCatService.entitlementId: _entitlement()});
    await tester.tap(find.text(SettingsStrings.storeSubscription));
    await tester.pumpAndSettle();

    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsOneWidget);
    expect(find.text(PaymentStrings.subscriptionRestoredTitle), findsNothing);

    // Exactly once — dismissing it must not bring it back.
    await tester.tap(find.text(PaymentStrings.subscriptionSuccessCta));
    await tester.pumpAndSettle();
    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsNothing);
  });

  testWidgets('a restored result shows the restored-purchases dialog',
      (tester) async {
    final client = _FakeClient()..paywallResult = PaywallResult.restored;
    final service = RevenueCatService.forTest(client);
    await service.init();

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    client.info = _customerInfo(
        active: {RevenueCatService.entitlementId: _entitlement()});
    await tester.tap(find.text(SettingsStrings.storeSubscription));
    await tester.pumpAndSettle();

    expect(find.text(PaymentStrings.subscriptionRestoredTitle), findsOneWidget);
    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsNothing);
  });

  for (final result in [
    PaywallResult.cancelled,
    PaywallResult.error,
    PaywallResult.notPresented,
  ]) {
    testWidgets('a $result result never shows the unlock dialog',
        (tester) async {
      final client = _FakeClient()..paywallResult = result;
      final service = RevenueCatService.forTest(client);
      await service.init();

      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();

      await tester.tap(find.text(SettingsStrings.storeSubscription));
      await tester.pumpAndSettle();

      expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsNothing);
      expect(find.text(PaymentStrings.subscriptionRestoredTitle), findsNothing);
    });
  }

  testWidgets(
      'an already-active subscriber opens the Customer Center instead of the paywall',
      (tester) async {
    final client = _FakeClient()
      ..info = _customerInfo(
          active: {RevenueCatService.entitlementId: _entitlement()});
    final service = RevenueCatService.forTest(client);
    await service.init();
    expect(service.isPlusActive, isTrue);

    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text(SettingsStrings.storeSubscription));
    await tester.pumpAndSettle();

    expect(client.presentCustomerCenterCount, 1);
    expect(find.text(PaymentStrings.subscriptionSuccessTitle), findsNothing);
  });
}
