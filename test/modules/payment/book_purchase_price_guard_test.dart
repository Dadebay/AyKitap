import 'package:aykitap/core/localization/strings/book_detail_strings.dart';
import 'package:aykitap/core/models/book_detail.dart';
import 'package:aykitap/modules/payment/book_purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checkout does not show a zero price when API omits price',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: BookPurchaseScreen(book: BookDetail(id: 1, name: 'Unknown')),
    ));

    expect(find.text(BookDetailStrings.priceUnavailable), findsOneWidget);
    expect(find.textContaining('0 TMT'), findsNothing);
  });
}
