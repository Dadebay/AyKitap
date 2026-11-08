import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/services/onesignal_client.dart';
import 'package:aykitap/core/services/onesignal_service.dart';
import 'package:aykitap/core/services/onesignal_tags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the service asked the SDK to do, without a platform channel.
class _FakeOneSignalClient implements OneSignalClient {
  _FakeOneSignalClient({this.initializeThrows = false});

  final bool initializeThrows;

  final List<String> initializedWith = <String>[];
  final List<String> loggedInAs = <String>[];
  final List<Map<String, dynamic>> addedTags = <Map<String, dynamic>>[];
  final List<List<String>> removedTagKeys = <List<String>>[];
  int logoutCount = 0;
  int optInCount = 0;
  int optOutCount = 0;
  bool permission = false;
  bool? optedIn;
  void Function(OneSignalClickPayload)? clickListener;

  @override
  Future<void> initialize(String appId) async {
    if (initializeThrows) throw StateError('OneSignal unreachable');
    initializedWith.add(appId);
  }

  @override
  Future<void> login(String externalId) async => loggedInAs.add(externalId);

  @override
  Future<void> logout() async => logoutCount++;

  @override
  Future<void> addTags(Map<String, dynamic> tags) async => addedTags.add(tags);

  @override
  Future<void> removeTags(List<String> keys) async => removedTagKeys.add(keys);

  @override
  Future<bool> requestPermission({required bool fallbackToSettings}) async =>
      permission;

  @override
  bool get hasPermission => permission;

  @override
  Future<void> optIn() async {
    optInCount++;
    optedIn = true;
  }

  @override
  Future<void> optOut() async {
    optOutCount++;
    optedIn = false;
  }

  @override
  bool? get isOptedIn => optedIn;

  @override
  void addClickListener(void Function(OneSignalClickPayload event) onClick) {
    clickListener = onClick;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('external id', () {
    test('is the backend user id, namespaced — never a phone or token', () {
      expect(OneSignalService.externalIdFor(42), 'user_42');
    });
  });

  group('initialize', () {
    test('binds the click listener and pushes tags once up', () async {
      final client = _FakeOneSignalClient();
      final service = OneSignalService.forTest(client);

      await service.initialize();

      expect(service.isReady, isTrue);
      expect(client.initializedWith, [OneSignalService.appId]);
      expect(client.clickListener, isNotNull);
      expect(client.addedTags, hasLength(1));
    });

    test('no app id configured is a safe no-op — the SDK is never touched',
        () async {
      final client = _FakeOneSignalClient();
      final service = OneSignalService.forTest(client, appId: '');

      await service.initialize();

      expect(service.isReady, isFalse);
      expect(client.initializedWith, isEmpty);
      expect(client.clickListener, isNull);
      expect(service.hasPermission, isFalse);
    });

    test('a throwing SDK leaves the service inert, never rethrows', () async {
      final client = _FakeOneSignalClient(initializeThrows: true);
      final service = OneSignalService.forTest(client);

      // The contract main() depends on: this future completes normally, so
      // the unawaited init can't take startup — or Firebase — down with it.
      await expectLater(service.initialize(), completes);

      expect(service.isReady, isFalse);
      // And every later call stays a no-op rather than throwing on its own.
      await service.login(7);
      await service.syncTags();
      expect(client.loggedInAs, isEmpty);
      expect(client.addedTags, isEmpty);
      expect(await service.requestPermission(), isFalse);
    });
  });

  group('identity', () {
    test('login before init is queued, not lost', () async {
      final client = _FakeOneSignalClient();
      final service = OneSignalService.forTest(client);

      // Exactly the boot-time race: main() fires initialize() without
      // awaiting it while a restored session logs in.
      await service.login(99);
      expect(client.loggedInAs, isEmpty);

      await service.initialize();
      expect(client.loggedInAs, ['user_99']);
    });

    test('only the latest queued intent is applied', () async {
      final client = _FakeOneSignalClient();
      final service = OneSignalService.forTest(client);

      await service.login(1);
      await service.login(2);
      await service.initialize();

      expect(client.loggedInAs, ['user_2']);
    });

    test('logout clears the identity and every tag this app writes', () async {
      final client = _FakeOneSignalClient();
      final service = OneSignalService.forTest(client);
      await service.initialize();

      await service.login(5);
      await service.logout();

      expect(client.logoutCount, 1);
      // Without this a second account on the same device would inherit the
      // first one's streak/subscription segmentation.
      expect(client.removedTagKeys, [OneSignalTags.keys]);
    });
  });

  group('the Settings switch', () {
    test('off unsubscribes without touching OS permission', () async {
      final client = _FakeOneSignalClient()..permission = true;
      final service = OneSignalService.forTest(client);
      await service.initialize();
      expect(service.isSubscribed, isTrue);

      expect(await service.setSubscribed(false), isTrue);

      expect(client.optOutCount, 1);
      // The whole reason an in-app switch can exist: permission is untouched
      // (an app can't revoke its own), the subscription is what moved.
      expect(client.permission, isTrue);
      expect(service.isSubscribed, isFalse);
    });

    test('on resubscribes', () async {
      final client = _FakeOneSignalClient()
        ..permission = true
        ..optedIn = false;
      final service = OneSignalService.forTest(client);
      await service.initialize();
      expect(service.isSubscribed, isFalse);

      expect(await service.setSubscribed(true), isTrue);

      expect(client.optInCount, 1);
      expect(service.isSubscribed, isTrue);
    });

    test('reads as on while the SDK has not reported opt-in state yet',
        () async {
      final client = _FakeOneSignalClient()
        ..permission = true
        ..optedIn = null;
      final service = OneSignalService.forTest(client);
      await service.initialize();

      // Null is "not known yet", not "opted out" — reading it as the latter
      // would flash the switch off on every launch.
      expect(service.isSubscribed, isTrue);
    });

    test('no OS permission reads as off however the subscription stands',
        () async {
      final client = _FakeOneSignalClient()
        ..permission = false
        ..optedIn = true;
      final service = OneSignalService.forTest(client);
      await service.initialize();

      expect(service.isSubscribed, isFalse);
    });

    test('a stored "off" is re-applied on the next launch', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'notifications_enabled': false});
      final client = _FakeOneSignalClient()..permission = true;
      final service = OneSignalService.forTest(client);

      await service.initialize();

      expect(client.optOutCount, 1);
      // Never the other direction: opting in prompts for permission, and a
      // boot-time restore must not raise a prompt.
      expect(client.optInCount, 0);
    });

    test('a stored "on" does not opt in at boot — that would prompt', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'notifications_enabled': true});
      final client = _FakeOneSignalClient()..permission = true;
      final service = OneSignalService.forTest(client);

      await service.initialize();

      expect(client.optInCount, 0);
      expect(client.optOutCount, 0);
    });
  });

  group('tags', () {
    test('carry only coarse, non-identifying values', () {
      final tags = OneSignalTags.build(
        language: AppLanguageCode.tk,
        currentStreak: 5,
        hasDownloadedBook: true,
        isPremium: false,
        permission: NotificationPermissionState.notDetermined,
      );

      expect(tags, {
        'app_language': 'tk',
        'current_streak_bucket': '4_6',
        'has_downloaded_book': 'true',
        'subscription_state': 'free',
        'notification_permission': 'not_determined',
      });
      expect(tags.keys.toSet(), OneSignalTags.keys.toSet());
    });

    test('streak buckets never leak the exact count', () {
      expect(OneSignalTags.streakBucket(0), '0');
      expect(OneSignalTags.streakBucket(1), '1_3');
      expect(OneSignalTags.streakBucket(3), '1_3');
      expect(OneSignalTags.streakBucket(4), '4_6');
      expect(OneSignalTags.streakBucket(6), '4_6');
      expect(OneSignalTags.streakBucket(7), '7_plus');
      expect(OneSignalTags.streakBucket(365), '7_plus');
    });
  });
}
