import 'package:aykitap/core/localization/app_locale.dart';
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

EntitlementInfo _entitlement() => const EntitlementInfo(
      RevenueCatService.entitlementId,
      true,
      true,
      '2024-01-01T00:00:00Z',
      '2024-01-01T00:00:00Z',
      'aykitap_pro_month',
      false,
    );

class _FakeClient implements RevenueCatClient {
  CustomerInfo info = _customerInfo();
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
      PaywallResult.notPresented;

  @override
  Future<PaywallResult> presentPaywallIfNeeded(String entitlementId,
          {Offering? offering}) async =>
      PaywallResult.notPresented;

  @override
  Future<void> presentCustomerCenter() async {
    presentCustomerCenterCount++;
  }
}

Widget _app(RevenueCatService revenueCat,
        Future<void> Function(BuildContext) openSubscription) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>.value(value: AppTheme.instance),
        ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
        ChangeNotifierProvider<RevenueCatService>.value(value: revenueCat),
      ],
      child: MaterialApp(
        home: SettingsScreen(openSubscription: openSubscription),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('inactive subscriber opens the subscription route',
      (tester) async {
    final client = _FakeClient();
    final service = RevenueCatService.forTest(client);
    await service.init();
    var routeCount = 0;

    await tester.pumpWidget(_app(service, (_) async => routeCount++));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.storeSubscription));
    await tester.pumpAndSettle();

    expect(routeCount, 1);
    expect(client.presentCustomerCenterCount, 0);
  });

  testWidgets('active subscriber opens Customer Center', (tester) async {
    final client = _FakeClient()
      ..info = _customerInfo(active: {
        RevenueCatService.entitlementId: _entitlement(),
      });
    final service = RevenueCatService.forTest(client);
    await service.init();
    var routeCount = 0;

    await tester.pumpWidget(_app(service, (_) async => routeCount++));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.storeSubscription));
    await tester.pumpAndSettle();

    expect(client.presentCustomerCenterCount, 1);
    expect(routeCount, 0);
  });
}
