# Tariffs: the subscription screen died on the new 7-day plan

```
Unhandled Exception: type 'Null' is not a subtype of type 'int' in type cast
#0  new Tariff.fromJson (package:aykitap/core/models/tariff.dart:26:41)
#1  PaymentApiService.getTariffs.<anonymous closure>
#9  _SubscriptionScreenActions._loadTariffs
```

## Not bad data — a new kind of plan

`GET /payments/tariffs` now returns a 7-day plan:

```json
{ "id": 5, "day_count": 7, "month_count": null, "price": 10, ... }
```

`month_count` is null because the plan isn't measured in months. Every row —
including this one — carries `day_count`, and always has. The client was
reading each plan's length out of `month_count` and hard-casting it, so the
first day-based plan the backend added took the whole screen down.

Worth noting how it failed: the cast throws a `TypeError`, `_loadTariffs`
catches only `ApiException`, so nothing caught it. `_loading` stayed true and
the screen sat on its spinner forever rather than showing the error state it
has.

## Client

`Tariff` is now built around `day_count`:

* `dayCount` is the length; `monthCount` is `int?` and only used for wording.
* `lengthInDays` falls back through `monthCount × 30` to 30, so nothing
  downstream can divide by zero on a malformed row.
* `pricePerMonth` = `price × 30 / lengthInDays`. For every plan that existed
  before this reproduces the old `price / monthCount` figure exactly (their
  `day_count` is `month_count × 30`), and it is defined for day-based plans
  too — `PlanCard` used to divide by null here.
* `subscriptionPlanLabel` names a monthless plan from its days ("Hepdelik" at
  7, `planDaysGeneric` otherwise) instead of rendering "null aýlyk".
* Ints are parsed leniently — int, double or numeric string — matching what
  this backend already does elsewhere (`book_count`, `progress`).

Two fields the response carries that the app had been ignoring are now
honoured, via `visibleTariffsInOrder`: `is_active` (switched-off plans are no
longer offered; a missing flag still reads as visible) and `sort_order` (ties
broken by length, since the weekly and monthly plans both sit at 0).

## What the backend needs to do

The app fix only helps once a new build is out. **Every already-installed
copy still crashes on this response**, because the released build parses every
row it is given and has no `is_active` filter — hiding the plan that way
won't help it either.

To unblock installed builds, one of:

1. **Don't return the 7-day plan** from `/payments/tariffs` until the updated
   app ships. This is the clean option.
2. **Give it a non-null integer `month_count`.** It has to be `1`; verified
   against the released build's own arithmetic:

   | `month_count` | released build |
   |---|---|
   | `1` | works — but labelled "Aýlyk" and priced "10 TMT/aý", undercutting the real monthly plan |
   | `0` | **still crashes** — `10 / 0` is Infinity, `Infinity.toInt()` throws `Unsupported operation: Infinity or NaN toInt` |
   | `-1` | shows "-10 TMT/aý" |

Going forward the contract the app now relies on:

* `day_count` non-null on every plan — this is the length the app reads.
* `month_count` may be null for anything that isn't whole months.
* `is_active` / `sort_order` are honoured from this build on.

## Follow-up: the weekly card quoted a monthly rate

With the crash gone the card read "Hepdelik / Aýda 42.9 TMT / 10 TMT". The
42.9 is arithmetically right — it is what a week at 10 TMT works out to over
a month — but sitting beside the plan's own 10 TMT price it reads as a
mistake rather than as a comparison, and it is money nobody hands over.

A plan is now quoted in its own unit: per month at a month or longer, per
week below that (`Tariff.isShorterThanAMonth`, `pricePerWeek`,
`PaymentStrings.weeklyEquivalent`). The weekly card reads "Hepdede 10 TMT";
every existing plan's line is untouched.

## One decision left open

`bestSubscriptionPlanIndex` pre-selects the biggest *percentage* discount.
With the weekly plan present that is now the 7-day one (16.7%), while the
cheapest per month is the 360-day plan (22.08 vs 42.86 TMT). The list widget's
own comment already claims the selection "stays on whichever tariff is
actually cheapest per month", which the code has never done. Left as-is and
pinned by a test — switching it is a commercial call, not a bug fix.

## Changed files

- `lib/core/models/tariff.dart`
- `lib/core/services/payment_api_service.dart`
- `lib/modules/payment/subscription_plan_helpers.dart`
- `lib/modules/payment/widgets/plan_card.dart`
- `lib/core/localization/strings/payment_strings.dart`
- `test/core/models/tariff_test.dart` (new, 14 tests)

## Verification

The test fixture is the real response verbatim. `flutter test
test/core/models/tariff_test.dart` — 14/14. `flutter analyze` clean.
`flutter test` — 342 pass, 2 fail, both the long-standing
`settings_screen_revenue_cat_test.dart` failures from the in-progress
RevenueCat/IAP work.
