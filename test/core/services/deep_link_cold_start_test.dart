import 'package:aykitap/core/navigation/root_navigator.dart';
import 'package:aykitap/core/services/deep_link_service.dart';
import 'package:aykitap/core/services/last_read_book_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('com.aykitap.aykitap/deep_link');

/// Mounts a bare app shell that owns [rootNavigatorKey], which is what
/// DeepLinkService treats as "there is somewhere to open into now".
Future<void> _mountShell(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    navigatorKey: rootNavigatorKey,
    home: const Scaffold(body: SizedBox.shrink()),
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final opened = <Uri>[];

  setUp(() {
    opened.clear();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DeepLinkService.instance.resetForTest();
    DeepLinkService.instance.openOverride = (uri) async => opened.add(uri);
    // The native side isn't there under `flutter test`; a cold start with no
    // launch link is the case being modelled anyway.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    DeepLinkService.instance.resetForTest();
  });

  testWidgets('a push tapped before the shell exists is not lost',
      (tester) async {
    // A notification tapped from a terminated app routes through here long
    // before MainNavScreen mounts.
    await DeepLinkService.instance
        .handleNotificationData({'route': 'streak', 'campaign': 'shipaton'});

    expect(opened, isEmpty, reason: 'nothing to open into yet');
    expect(DeepLinkService.instance.pendingLink, Uri.parse('aykitap://streak'));

    await _mountShell(tester);
    DeepLinkService.instance.init();
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('aykitap://streak')]);
  });

  testWidgets('a pending link is opened exactly once', (tester) async {
    await DeepLinkService.instance.handleUri(Uri.parse('aykitap://streak'));
    await _mountShell(tester);

    DeepLinkService.instance.init();
    await tester.pumpAndSettle();
    // Whatever else re-enters — a second shell mount, a re-init — the queued
    // link must not reopen behind the user.
    DeepLinkService.instance.init();
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(DeepLinkService.instance.pendingLink, isNull);
  });

  testWidgets('with the shell up, a tap opens straight away', (tester) async {
    await _mountShell(tester);
    DeepLinkService.instance.init();
    await tester.pumpAndSettle();

    await DeepLinkService.instance
        .handleNotificationData({'route': 'book', 'bookId': '31'});
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('aykitap://book/31')]);
    expect(DeepLinkService.instance.pendingLink, isNull);
  });

  testWidgets('reader_last resolves the last book from the device',
      (tester) async {
    // Seeded the way the app stores it — the campaign carries no book id, so
    // this is the only place the book can come from.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_read_catalogue_book_v1':
          '{"book_id":77,"title":"Oyunbaz","path":"/tmp/x.pdf",'
              '"format":"pdf","page_count":488,"page":7}',
    });

    await _mountShell(tester);
    DeepLinkService.instance.init();
    await tester.pumpAndSettle();

    await DeepLinkService.instance
        .handleNotificationData({'route': 'reader_last'});
    await tester.pumpAndSettle();

    expect(opened, [Uri.parse('aykitap://$kLastReadDeepLinkHost')]);

    // And the store really does hold the book that route resolves against.
    await LastReadBookStore.instance.load();
    expect(LastReadBookStore.instance.book?.bookId, 77);
  });
}
