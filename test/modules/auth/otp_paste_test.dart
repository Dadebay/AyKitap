import 'package:aykitap/modules/auth/otp_verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dio_adapter.dart';

/// Regression test for the iOS bug: long-press "Paste" hands the whole
/// clipboard string to whichever OTP box is focused. That box previously had
/// `maxLength: 1`, so Flutter's own length-limiting formatter silently
/// truncated the paste down to its first character before `onChanged` ever
/// saw the rest — the code above every box past the first stayed empty. See
/// [OtpCodeRow]'s and [OtpVerifyScreen._fillFromPastedCode]'s doc comments
/// for the fix.
void main() {
  // `AuthProvider` isn't touched by these cases (fewer than 4 digits never
  // reaches `_verify()`), but `installFakeSecureStorage` still has to run:
  // `DioClient`'s request interceptor reads the bearer token on construction
  // via a method channel with no test-time implementation.
  setUp(installFakeSecureStorage);

  Future<void> pumpOtpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OtpVerifyScreen(phone: '+99361234567'),
    ));
    await tester.pump();
  }

  testWidgets(
      'pasting the full code into the first box fills every box, not just the first',
      (tester) async {
    await pumpOtpScreen(tester);

    // A 3-digit paste (not 4) deliberately stays short of `_verify()`'s
    // auto-submit threshold, so this stays a pure UI assertion — no network
    // call to stand up a fake backend for.
    await tester.enterText(find.byType(TextField).at(0), '123');
    await tester.pump();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '1');
    expect(fields[1].controller!.text, '2');
    expect(fields[2].controller!.text, '3');
    expect(fields[3].controller!.text, '');
  });

  testWidgets('a paste landing in a middle box still fills from the start',
      (tester) async {
    await pumpOtpScreen(tester);

    // The reported case: the paste bubble can appear over whichever box
    // happens to be focused, not necessarily the first one.
    await tester.enterText(find.byType(TextField).at(2), '456');
    await tester.pump();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '4');
    expect(fields[1].controller!.text, '5');
    expect(fields[2].controller!.text, '6');
    expect(fields[3].controller!.text, '');
  });

  testWidgets('typing a single digit still behaves exactly as before',
      (tester) async {
    await pumpOtpScreen(tester);

    await tester.enterText(find.byType(TextField).at(0), '7');
    await tester.pump();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller!.text, '7');
    expect(fields[1].controller!.text, '');
  });
}
