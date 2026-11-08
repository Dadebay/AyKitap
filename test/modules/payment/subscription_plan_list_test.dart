import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:aykitap/core/models/tariff.dart';
import 'package:aykitap/modules/payment/widgets/plan_card.dart';
import 'package:aykitap/modules/payment/widgets/subscription_plan_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the most-popular badge on the 3-month plan',
      (tester) async {
    const tariffs = [
      Tariff(id: 3, dayCount: 90, monthCount: 3, price: 70),
      Tariff(id: 6, dayCount: 180, monthCount: 6, price: 135),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SubscriptionPlanList(
          loading: false,
          error: null,
          tariffs: tariffs,
          selected: 0,
          onRetry: () {},
          onSelect: (_) {},
        ),
      ),
    ));

    final threeMonths = find.byWidgetPredicate(
      (widget) => widget is PlanCard && widget.tariff.monthCount == 3,
    );
    final sixMonths = find.byWidgetPredicate(
      (widget) => widget is PlanCard && widget.tariff.monthCount == 6,
    );

    expect(
      find.descendant(
        of: threeMonths,
        matching: find.text(PaymentStrings.mostPopular),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sixMonths,
        matching: find.text(PaymentStrings.mostPopular),
      ),
      findsNothing,
    );
  });
}
