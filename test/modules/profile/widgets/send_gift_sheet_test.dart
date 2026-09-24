// A gift larger than the sender's balance used to fail invisibly: the
// backend's 400 was reported with [AppSnackBar], which floats at the bottom
// of the screen — behind the sheet and the keyboard it opens with — so the
// reader saw a Send button that appeared to do nothing and tapped it again
// (two identical "not enough balance" rejections in the device log is what
// surfaced this). The refusal is now stated inside the sheet, and caught on
// the device before the request is made at all.
import 'dart:convert';

import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/gift_strings.dart';
import 'package:aykitap/core/network/account_endpoints.dart';
import 'package:aykitap/core/network/dio_client.dart';
import 'package:aykitap/core/services/account_service.dart';
import 'package:aykitap/modules/profile/widgets/send_gift_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_dio_adapter.dart';

/// Answers only the three endpoints this sheet touches, and records what was
/// actually sent so the test can prove the transfer never left the device.
class _GiftAdapter implements HttpClientAdapter {
  _GiftAdapter({required this.balance});

  final int balance;
  final List<RequestOptions> requests = [];

  bool get sentGift =>
      requests.any((r) => r.path == AccountEndpoints.sendToFriend);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final body = switch (options.path) {
      AccountEndpoints.isUserExists => {
          'data': {'userExists': true}
        },
      AccountEndpoints.sendToFriend => {'data': null},
      _ => {
          'data': {'id': 1, 'balance': balance}
        },
    };
    return ResponseBody.fromString(jsonEncode(body), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AccountService>.value(
      value: AccountService.instance,
      child: const MaterialApp(
        home: Scaffold(body: SendGiftSheet()),
      ),
    ),
  );
}

/// Fills in an amount and a complete recipient phone, then waits out the
/// 500ms debounce on the "is this a real user" lookup — the Send button
/// stays disabled until that lookup has answered.
///
/// Every wait in this file is an explicit [WidgetTester.pump]. Settling is
/// impossible here: [GiftSheetFrame]'s animated border runs off a controller
/// in `repeat()`, so no frame ever leaves the tree quiet and a settle call
/// just spins until its own ten-minute timeout.
Future<void> _fillIn(WidgetTester tester, {required String amount}) async {
  await tester.enterText(find.byType(TextField).first, amount);
  await tester.pump();
  await tester.enterText(find.byType(TextField).last, '12345678');
  // Past the 500ms debounce, then two frames for the lookup's response to
  // land and the Send button to rebuild as enabled.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _GiftAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    installFakeSecureStorage();
    await AppLocale.instance.setLanguage(AppLanguageCode.tk);
  });

  Future<void> useBalance(int balance) async {
    adapter = _GiftAdapter(balance: balance);
    DioClient.instance.httpClientAdapter = adapter;
    await AccountService.instance.refresh();
  }

  testWidgets('sending more than the balance is refused inside the sheet',
      (tester) async {
    await useBalance(10);
    await _pumpSheet(tester);
    await _fillIn(tester, amount: '101');

    await tester.tap(find.text(GiftStrings.sendWithAmount(101)));
    await tester.pump();

    expect(find.text(GiftStrings.insufficientBalance(10)), findsOneWidget);
    // The point of checking on the device: nothing was sent to be rejected.
    expect(adapter.sentGift, isFalse);
  });

  testWidgets('the refusal clears as soon as the amount is edited',
      (tester) async {
    await useBalance(10);
    await _pumpSheet(tester);
    await _fillIn(tester, amount: '101');
    await tester.tap(find.text(GiftStrings.sendWithAmount(101)));
    await tester.pump();
    expect(find.text(GiftStrings.insufficientBalance(10)), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pump();

    expect(find.text(GiftStrings.insufficientBalance(10)), findsNothing);
  });

  testWidgets('an amount the balance covers is sent', (tester) async {
    await useBalance(500);
    await _pumpSheet(tester);
    await _fillIn(tester, amount: '101');

    await tester.tap(find.text(GiftStrings.sendWithAmount(101)));
    await tester.pump();
    await tester.pump();

    expect(adapter.sentGift, isTrue);
    expect(find.text(GiftStrings.insufficientBalance(500)), findsNothing);
  });
}
