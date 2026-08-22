import '../../core/models/tariff.dart';
import '../../core/localization/strings/payment_strings.dart';

/// The best-value plan (biggest discount) among [tariffs] — the default
/// selection, since there's no fixed "monthly is always index 1" to lean on
/// with a dynamic tariff list.
int bestSubscriptionPlanIndex(List<Tariff> tariffs) {
  var best = 0;
  for (var i = 1; i < tariffs.length; i++) {
    if (tariffs[i].discountPercent > tariffs[best].discountPercent) best = i;
  }
  return best;
}

/// The plan-length label [SubscriptionScreen] shows on each [PlanCard] and
/// in the success dialog.
String subscriptionPlanLabel(Tariff tariff) {
  switch (tariff.monthCount) {
    case 1:
      return PaymentStrings.planMonthly;
    case 3:
      return PaymentStrings.plan3Months;
    case 6:
      return PaymentStrings.plan6Months;
    case 12:
      return PaymentStrings.planYearly;
    default:
      return PaymentStrings.planMonthsGeneric(tariff.monthCount);
  }
}
