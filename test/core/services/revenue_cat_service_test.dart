import 'package:aykitap/core/services/revenue_cat_client.dart';
import 'package:aykitap/core/services/revenue_cat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

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

EntitlementInfo _entitlement({String? expirationDate}) {
  return EntitlementInfo(
    RevenueCatService.entitlementId,
    true,
    true,
    '2024-01-01T00:00:00Z',
    '2024-01-01T00:00:00Z',
    'aykitap_pro_month',
    false,
    expirationDate: expirationDate,
  );
}

/// Records what the service asked the SDK to do, without a platform
/// channel — same shape as `_FakeOneSignalClient`.
class _FakeRevenueCatClient implements RevenueCatClient {
  CustomerInfo info = _customerInfo();
  final List<String> loggedInAs = <String>[];
  int logoutCount = 0;
  int configureCount = 0;
  int presentCustomerCenterCount = 0;

  /// What [presentPaywallIfNeeded]/[presentPaywall] return — set per test to
  /// drive each of [PaywallResult]'s five outcomes. [info] is what the
  /// following [getCustomerInfo] call (from [RevenueCatService]'s own
  /// post-purchase `refreshCustomerInfo()`) reports back.
  PaywallResult paywallResult = PaywallResult.notPresented;

  @override
  Future<void> configure(String apiKey, {required bool debugLogging}) async {
    configureCount++;
  }

  @override
  void addCustomerInfoUpdateListener(
      void Function(CustomerInfo info) listener) {}

  @override
  Future<CustomerInfo> getCustomerInfo() async => info;

  @override
  Future<CustomerInfo> logIn(String appUserId) async {
    loggedInAs.add(appUserId);
    return info;
  }

  @override
  Future<CustomerInfo> logOut() async {
    logoutCount++;
    info = _customerInfo();
    return info;
  }

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

/// Fails `configure` on its first call, succeeds from the second call on —
/// for proving a failed [RevenueCatService.init] doesn't get permanently
/// cached and can be retried.
class _FailingThenSucceedingClient extends _FakeRevenueCatClient {
  @override
  Future<void> configure(String apiKey, {required bool debugLogging}) async {
    configureCount++;
    if (configureCount == 1) throw Exception('no network');
  }
}

void main() {
  group('RevenueCatService', () {
    test('uses the backend and dashboard premium entitlement identifier', () {
      expect(RevenueCatService.entitlementId, 'premium');
    });

    test('isPlusActive is false before init', () {
      final service = RevenueCatService.forTest(_FakeRevenueCatClient());
      expect(service.isPlusActive, isFalse);
    });

    test('init loads customer info and flips isPlusActive on', () async {
      final client = _FakeRevenueCatClient()
        ..info = _customerInfo(active: {
          RevenueCatService.entitlementId: _entitlement(),
        });
      final service = RevenueCatService.forTest(client);

      await service.init();

      expect(client.configureCount, 1);
      expect(service.isPlusActive, isTrue);
    });

    test('login before init queues and flushes once ready', () async {
      final client = _FakeRevenueCatClient();
      final service = RevenueCatService.forTest(client);

      // Called before init resolves — matches an OTP login landing before
      // RevenueCatService.init() finishes on a cold start.
      final loginFuture = service.login(42);
      await service.init();
      await loginFuture;

      expect(client.loggedInAs, ['user_42']);
    });

    test('logout before init queues and flushes once ready', () async {
      final client = _FakeRevenueCatClient();
      final service = RevenueCatService.forTest(client);

      final logoutFuture = service.logout();
      await service.init();
      await logoutFuture;

      expect(client.logoutCount, 1);
    });

    test(
        'a logout queued after a pending login never applies the stale '
        'login — the old user\'s access does not carry over', () async {
      final client = _FakeRevenueCatClient()
        ..info = _customerInfo(active: {
          RevenueCatService.entitlementId: _entitlement(),
        });
      final service = RevenueCatService.forTest(client);

      // A login lands (e.g. a stale OTP callback for a premium account),
      // then — before init flushes either — a logout arrives. Only the
      // logout should reach the client; the queued login must not
      // resurrect that account's access first.
      final loginFuture = service.login(42);
      final logoutFuture = service.logout();
      await service.init();
      await Future.wait([loginFuture, logoutFuture]);

      expect(client.loggedInAs, isEmpty);
      expect(client.logoutCount, 1);
      expect(service.isPlusActive, isFalse);
    });

    test('concurrent init() calls configure exactly once', () async {
      // main() fires init() without awaiting it, so nothing here can rely
      // on being the only caller in flight — a second call (another
      // widget's rebuild, a retry) must share the same attempt rather than
      // configuring the SDK a second time.
      final client = _FakeRevenueCatClient();
      final service = RevenueCatService.forTest(client);

      final first = service.init();
      final second = service.init();
      await Future.wait([first, second]);

      expect(client.configureCount, 1);
      expect(service.isReady, isTrue);
    });

    test('a failed init is not cached — the next call retries', () async {
      final client = _FailingThenSucceedingClient();
      final service = RevenueCatService.forTest(client);

      await service.init();
      expect(service.isReady, isFalse);
      expect(client.configureCount, 1);

      await service.init();
      expect(service.isReady, isTrue);
      expect(client.configureCount, 2);
    });

    test('plusExpiresAt parses the active entitlement expiration', () async {
      final client = _FakeRevenueCatClient()
        ..info = _customerInfo(active: {
          RevenueCatService.entitlementId:
              _entitlement(expirationDate: '2030-06-15T00:00:00Z'),
        });
      final service = RevenueCatService.forTest(client);

      await service.init();

      expect(service.plusExpiresAt, DateTime.parse('2030-06-15T00:00:00Z'));
    });

    test('plusExpiresAt is null without an active entitlement', () async {
      final service = RevenueCatService.forTest(_FakeRevenueCatClient());
      await service.init();

      expect(service.plusExpiresAt, isNull);
    });

    test('presentCustomerCenter delegates to the client', () async {
      final client = _FakeRevenueCatClient();
      final service = RevenueCatService.forTest(client);
      await service.init();

      await service.presentCustomerCenter();

      expect(client.presentCustomerCenterCount, 1);
    });

    test('a purchased paywall result refreshes isPlusActive to true', () async {
      final client = _FakeRevenueCatClient()
        ..paywallResult = PaywallResult.purchased;
      final service = RevenueCatService.forTest(client);
      await service.init();
      expect(service.isPlusActive, isFalse);

      // The SDK's own customer info reflects the new entitlement by the
      // time RevenueCatService's post-purchase refresh reads it.
      client.info = _customerInfo(
          active: {RevenueCatService.entitlementId: _entitlement()});
      final result = await service.presentPaywallIfNeeded();

      expect(result, PaywallResult.purchased);
      expect(service.isPlusActive, isTrue);
    });

    test('a restored paywall result refreshes isPlusActive to true', () async {
      final client = _FakeRevenueCatClient()
        ..paywallResult = PaywallResult.restored;
      final service = RevenueCatService.forTest(client);
      await service.init();

      client.info = _customerInfo(
          active: {RevenueCatService.entitlementId: _entitlement()});
      final result = await service.presentPaywallIfNeeded();

      expect(result, PaywallResult.restored);
      expect(service.isPlusActive, isTrue);
    });

    for (final result in [
      PaywallResult.cancelled,
      PaywallResult.error,
      PaywallResult.notPresented,
    ]) {
      test('a $result paywall result leaves isPlusActive unchanged', () async {
        final client = _FakeRevenueCatClient()..paywallResult = result;
        final service = RevenueCatService.forTest(client);
        await service.init();
        expect(service.isPlusActive, isFalse);

        // Even if the SDK's info happens to carry the entitlement, a
        // cancelled/error/notPresented result must never trigger a refresh
        // that would surface it — only purchased/restored do.
        client.info = _customerInfo(
            active: {RevenueCatService.entitlementId: _entitlement()});
        final actual = await service.presentPaywallIfNeeded();

        expect(actual, result);
        expect(service.isPlusActive, isFalse);
      });
    }
  });
}
