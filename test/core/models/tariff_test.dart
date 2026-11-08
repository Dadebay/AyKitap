// The subscription screen crashed with `type 'Null' is not a subtype of type
// 'int' in type cast` once the backend added a 7-day plan: that plan is
// measured in days, so its `month_count` is null, and the model read every
// plan's length out of that field.
//
// The fixture below is the real `GET /payments/tariffs` response from the
// build that crashed.
import 'package:aykitap/core/localization/app_locale.dart';
import 'package:aykitap/core/localization/strings/payment_strings.dart';
import 'package:aykitap/core/models/tariff.dart';
import 'package:aykitap/modules/payment/subscription_plan_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _liveResponse = <Map<String, dynamic>>[
  {
    'id': 5,
    'day_count': 7,
    'price': 10,
    'actual_price': 12,
    'price_usd': 1,
    'actual_price_usd': 1.99,
    'is_active': true,
    'sort_order': 0,
    'month_count': null,
  },
  {
    'id': 1,
    'day_count': 30,
    'price': 25,
    'actual_price': 25,
    'is_active': true,
    'sort_order': 0,
    'month_count': 1,
  },
  {
    'id': 2,
    'day_count': 90,
    'price': 70,
    'actual_price': 75,
    'is_active': true,
    'sort_order': 1,
    'month_count': 3,
  },
  {
    'id': 3,
    'day_count': 180,
    'price': 135,
    'actual_price': 150,
    'is_active': true,
    'sort_order': 2,
    'month_count': 6,
  },
  {
    'id': 4,
    'day_count': 360,
    'price': 265,
    'actual_price': 300,
    'is_active': true,
    'sort_order': 3,
    'month_count': 12,
  },
];

List<Tariff> _parsed() =>
    _liveResponse.map(Tariff.fromJson).toList(growable: false);

Tariff _byId(int id) => _parsed().firstWhere((t) => t.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLocale.instance.setLanguage(AppLanguageCode.tk);
  });

  group('parsing the response that crashed', () {
    test('the whole list parses', () {
      expect(_parsed(), hasLength(5));
    });

    test('the day-based plan keeps its length and reports no months', () {
      final weekly = _byId(5);

      expect(weekly.dayCount, 7);
      expect(weekly.monthCount, isNull);
      expect(weekly.lengthInDays, 7);
    });

    test('month-aligned plans still carry their month count', () {
      expect(_byId(1).monthCount, 1);
      expect(_byId(4).monthCount, 12);
      expect(_byId(4).lengthInDays, 360);
    });

    test('a row missing every length still has a usable one', () {
      final broken = Tariff.fromJson({'id': 9, 'price': 5});

      expect(broken.lengthInDays, greaterThan(0));
      expect(() => broken.pricePerMonth, returnsNormally);
    });

    test('numbers arriving as strings or doubles are still read', () {
      final loose = Tariff.fromJson({
        'id': '7',
        'day_count': 30.0,
        'price': '25',
        'actual_price': 30.4,
      });

      expect(loose.id, 7);
      expect(loose.dayCount, 30);
      expect(loose.price, 25);
      expect(loose.actualPrice, 30);
    });
  });

  group('per-month price', () {
    test('is unchanged for every plan that existed before', () {
      // What `price / monthCount` produced before the model moved to days.
      expect(_byId(1).pricePerMonth, closeTo(25, 0.01));
      expect(_byId(2).pricePerMonth, closeTo(70 / 3, 0.01));
      expect(_byId(3).pricePerMonth, closeTo(135 / 6, 0.01));
      expect(_byId(4).pricePerMonth, closeTo(265 / 12, 0.01));
    });

    test('is now defined for the day-based plan too', () {
      expect(_byId(5).pricePerMonth, closeTo(10 * 30 / 7, 0.01));
    });
  });

  group('which unit a plan is quoted in', () {
    test('a plan of a month or more is quoted per month', () {
      for (final id in [1, 2, 3, 4]) {
        expect(_byId(id).isShorterThanAMonth, isFalse, reason: 'plan $id');
      }
    });

    test('the weekly plan is quoted per week, not per month', () {
      // "Aýda 42.9 TMT" beside a 10 TMT price read as a mistake: it is a
      // comparison figure, not money anyone hands over.
      final weekly = _byId(5);

      expect(weekly.isShorterThanAMonth, isTrue);
      expect(weekly.pricePerWeek, closeTo(10, 0.01));
    });

    test('a fortnightly plan is quoted per week too', () {
      const fortnight = Tariff(id: 8, dayCount: 14, price: 16);

      expect(fortnight.isShorterThanAMonth, isTrue);
      expect(fortnight.pricePerWeek, closeTo(8, 0.01));
    });

    test('a 30-day plan sits on the month side of the line', () {
      const monthly = Tariff(id: 9, dayCount: 30, price: 25);

      expect(monthly.isShorterThanAMonth, isFalse);
      expect(monthly.pricePerMonth, closeTo(25, 0.01));
    });
  });

  group('labels', () {
    test('the day-based plan reads as weekly, not "null aýlyk"', () {
      final label = subscriptionPlanLabel(_byId(5));

      expect(label, PaymentStrings.planWeekly);
      expect(label, isNot(contains('null')));
    });

    test('month-aligned plans keep the labels they had', () {
      expect(subscriptionPlanLabel(_byId(1)), PaymentStrings.planMonthly);
      expect(subscriptionPlanLabel(_byId(2)), PaymentStrings.plan3Months);
      expect(subscriptionPlanLabel(_byId(3)), PaymentStrings.plan6Months);
      expect(subscriptionPlanLabel(_byId(4)), PaymentStrings.planYearly);
    });

    test('some other day length falls back to a day count', () {
      const threeDay = Tariff(id: 8, dayCount: 3, price: 5);

      expect(
          subscriptionPlanLabel(threeDay), PaymentStrings.planDaysGeneric(3));
    });
  });

  group('which plans show, and in what order', () {
    test('the backend order wins, shortest first on a tie', () {
      // ids 5 and 1 both sit at sort_order 0; 7 days comes before 30.
      expect(visibleTariffsInOrder(_parsed()).map((t) => t.id).toList(),
          [5, 1, 2, 3, 4]);
    });

    test('a switched-off plan is not offered', () {
      final withHidden = [
        ..._parsed(),
        const Tariff(id: 99, dayCount: 14, price: 1, isActive: false),
      ];

      expect(visibleTariffsInOrder(withHidden).map((t) => t.id),
          isNot(contains(99)));
    });

    test('a plan with no is_active field is treated as visible', () {
      final noFlag = Tariff.fromJson({'id': 6, 'day_count': 30, 'price': 9});

      expect(visibleTariffsInOrder([noFlag]), hasLength(1));
    });
  });

  test('the default selection still follows the biggest discount', () {
    // Unchanged rule, but worth pinning: with the weekly plan present the
    // biggest *percentage* discount is no longer the cheapest per month.
    final ordered = visibleTariffsInOrder(_parsed());

    expect(ordered[bestSubscriptionPlanIndex(ordered)].id, 5);
    expect(
      ordered.reduce((a, b) => a.pricePerMonth < b.pricePerMonth ? a : b).id,
      4,
    );
  });
}
