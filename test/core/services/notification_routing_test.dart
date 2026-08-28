import 'package:aykitap/core/services/deep_link_service.dart';
import 'package:aykitap/core/services/firebase_messaging_service.dart';
import 'package:aykitap/core/services/notification_dedup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('campaign data → deep link URI', () {
    test('route=book opens the catalogue detail URI', () {
      expect(
        deepLinkUriFromNotificationData({'route': 'book', 'bookId': 12}),
        Uri.parse('aykitap://book/12'),
      );
    });

    test('route=reader opens the reader URI', () {
      expect(
        deepLinkUriFromNotificationData({'route': 'reader', 'bookId': 7}),
        Uri.parse('aykitap://reader/7'),
      );
    });

    test('bookId survives FCM flattening every value to a string', () {
      expect(
        deepLinkUriFromNotificationData({'route': 'book', 'bookId': '12'}),
        Uri.parse('aykitap://book/12'),
      );
    });

    test('route=reader_last needs no book id at all', () {
      // The whole point of this route: the campaign never learns which book
      // the reader is on — it is resolved on-device at tap time.
      final uri = deepLinkUriFromNotificationData({'route': 'reader_last'});
      expect(uri, isNotNull);
      expect(uri!.host, kLastReadDeepLinkHost);
      expect(uri.toString(), isNot(contains('bookId')));
    });

    test('route=streak opens the streak screen URI', () {
      expect(
        deepLinkUriFromNotificationData({'route': 'streak'}),
        Uri.parse('aykitap://streak'),
      );
    });

    test('incomplete or unknown campaigns route nowhere', () {
      // A malformed campaign should do nothing, not crash the app it just
      // reopened.
      expect(deepLinkUriFromNotificationData(const {}), isNull);
      expect(deepLinkUriFromNotificationData({'route': 'book'}), isNull);
      expect(
          deepLinkUriFromNotificationData({'route': 'reader', 'bookId': 'x'}),
          isNull);
      expect(deepLinkUriFromNotificationData({'route': 'book', 'bookId': 0}),
          isNull);
      expect(deepLinkUriFromNotificationData({'route': 'nonsense'}), isNull);
      expect(deepLinkUriFromNotificationData({'campaign': 'shipaton'}), isNull);
    });
  });

  group('OneSignal payloads are not re-shown by Firebase', () {
    test('a OneSignal FCM payload is recognised by its custom.i key', () {
      // OneSignal documents `custom.i` as required for their SDKs to process
      // a notification at all, so this is a structural check rather than a
      // guess at the message text.
      expect(
        FirebaseMessagingService.oneSignalNotificationId({
          'custom': '{"i":"a1b2c3","a":{"route":"streak"}}',
        }),
        'a1b2c3',
      );
    });

    test('an already-decoded custom map is accepted too', () {
      expect(
        FirebaseMessagingService.oneSignalNotificationId({
          'custom': {'i': 'decoded-id'},
        }),
        'decoded-id',
      );
    });

    test('a backend transactional payload is left alone', () {
      // Firebase must keep showing these — they are the provider's own
      // account/purchase/security traffic.
      expect(
        FirebaseMessagingService.oneSignalNotificationId(
            {'type': 'purchase', 'bookId': '3'}),
        isNull,
      );
      expect(
        FirebaseMessagingService.oneSignalNotificationId(
            {'custom': 'not json'}),
        isNull,
      );
      expect(
        FirebaseMessagingService.oneSignalNotificationId(
            {'custom': '{"i":""}'}),
        isNull,
      );
      expect(
        FirebaseMessagingService.oneSignalNotificationId({'custom': '[1,2]'}),
        isNull,
      );
    });
  });

  group('dedup', () {
    setUp(NotificationDedupService.instance.reset);

    test('the same notification is only ever claimed once', () {
      final dedup = NotificationDedupService.instance;
      expect(dedup.claim('os-open:abc'), isTrue);
      expect(dedup.claim('os-open:abc'), isFalse);
      expect(dedup.claim('os-open:abc'), isFalse);
    });

    test('showing and opening the same id are separate claims', () {
      final dedup = NotificationDedupService.instance;
      expect(dedup.claim('fcm-show:abc'), isTrue);
      expect(dedup.claim('os-open:abc'), isTrue);
    });

    test('a genuine re-send past the TTL is shown again', () {
      final dedup = NotificationDedupService.instance;
      final now = DateTime(2026, 8, 25, 12);
      expect(dedup.claim('os-open:abc', now: now), isTrue);
      expect(
        dedup.claim('os-open:abc',
            now: now.add(
                NotificationDedupService.ttl - const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        dedup.claim('os-open:abc', now: now.add(NotificationDedupService.ttl)),
        isTrue,
      );
    });
  });
}
