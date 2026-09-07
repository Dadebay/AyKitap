// Regression cover for PurchaseModeService — the single decision point
// APPLE_REVIEW_IOS_STORE_TOGGLE_PLAN.md §5.0 requires every payment surface
// to read instead of re-deriving the toggle/region logic itself. See the
// plan's §7 test matrix; these cases mirror it directly.
import 'package:aykitap/core/models/revenue_cat_config.dart';
import 'package:aykitap/core/services/purchase_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';

RevenueCatConfig _config({
  String purchaseMode = 'wallet',
  bool enabled = true,
  bool iosStoreIapOnlyEnabled = true,
}) =>
    RevenueCatConfig(
      appUserId: 'user_1',
      entitlementId: 'premium',
      enabled: enabled,
      billingRegion: purchaseMode == 'wallet' ? 'TM' : 'FOREIGN',
      displayCurrency: purchaseMode == 'wallet' ? 'TMT' : 'STORE_LOCALIZED',
      purchaseMode: purchaseMode,
      iosStoreIapOnlyEnabled: iosStoreIapOnlyEnabled,
    );

void main() {
  group('iOS', () {
    test('toggle true forces store checkout regardless of region', () async {
      final service = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async =>
            _config(purchaseMode: 'wallet', iosStoreIapOnlyEnabled: true),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isTrue);
      expect(service.useStoreCheckout, isTrue);
    });

    test('toggle false falls back to the existing region decision', () async {
      final service = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async =>
            _config(purchaseMode: 'wallet', iosStoreIapOnlyEnabled: false),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);
      expect(service.isRegionStoreIap, isFalse);
      expect(service.useStoreCheckout, isFalse);
    });

    test(
        'toggle false + foreign region resolves to store checkout via the '
        'region decision, not the toggle', () async {
      final service = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async => _config(
            purchaseMode: 'store_iap', iosStoreIapOnlyEnabled: false),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);
      expect(service.isRegionStoreIap, isTrue);
      expect(service.useStoreCheckout, isTrue);
    });

    test('a fetch failure fails closed to store-only, never wallet',
        () async {
      final service = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async => throw Exception('network down'),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isTrue);
      expect(service.useStoreCheckout, isTrue);
    });

    test(
        'a fetch failure after a confirmed-off toggle still reverts to '
        'store-only — an admin flip mid-review must not stay open on a '
        'dropped connection', () async {
      final service = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async =>
            _config(purchaseMode: 'wallet', iosStoreIapOnlyEnabled: false),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);

      final flaky = PurchaseModeService.forTest(
        isIOS: true,
        fetchConfig: (_) async => throw Exception('network down'),
      );
      await flaky.refresh();
      expect(flaky.isIOSStoreOnly, isTrue);
    });
  });

  group('Android', () {
    test('ignores the iOS toggle entirely even when the backend sends true',
        () async {
      final service = PurchaseModeService.forTest(
        isIOS: false,
        fetchConfig: (_) async =>
            _config(purchaseMode: 'wallet', iosStoreIapOnlyEnabled: true),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);
      expect(service.useStoreCheckout, isFalse);
    });

    test('foreign region resolves to store checkout via the region decision',
        () async {
      final service = PurchaseModeService.forTest(
        isIOS: false,
        fetchConfig: (_) async =>
            _config(purchaseMode: 'store_iap', iosStoreIapOnlyEnabled: true),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);
      expect(service.useStoreCheckout, isTrue);
    });

    test('a fetch failure fails closed to wallet, matching the pre-existing '
        'default', () async {
      final service = PurchaseModeService.forTest(
        isIOS: false,
        fetchConfig: (_) async => throw Exception('network down'),
      );
      await service.refresh();
      expect(service.isIOSStoreOnly, isFalse);
      expect(service.isRegionStoreIap, isFalse);
      expect(service.useStoreCheckout, isFalse);
    });
  });

  test('refresh() picks up a toggle flip without a new app install', () async {
    var iosStoreIapOnlyEnabled = true;
    final service = PurchaseModeService.forTest(
      isIOS: true,
      fetchConfig: (_) async =>
          _config(iosStoreIapOnlyEnabled: iosStoreIapOnlyEnabled),
    );
    await service.refresh();
    expect(service.isIOSStoreOnly, isTrue);

    iosStoreIapOnlyEnabled = false;
    await service.refresh();
    expect(service.isIOSStoreOnly, isFalse);
  });

  test('notifies listeners after each refresh so watching widgets rebuild',
      () async {
    final service = PurchaseModeService.forTest(
      isIOS: true,
      fetchConfig: (_) async => _config(),
    );
    var notified = 0;
    service.addListener(() => notified++);
    await service.refresh();
    expect(notified, 1);
    await service.refresh();
    expect(notified, 2);
  });
}
