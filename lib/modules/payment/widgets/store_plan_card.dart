import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// [PlanCard]'ın store-billed (RevenueCat [Package]) karşılığı — aynı
/// seçilebilir gradient çerçeve, ama TMT/[Tariff] yerine mağazanın kendi
/// yerelleştirilmiş fiyat metnini ([StoreProduct.priceString]) gösterir.
class StorePlanCard extends StatelessWidget {
  const StorePlanCard({
    super.key,
    required this.package,
    required this.label,
    this.best = false,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final String label;
  final bool best;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  /// Yearly's own [priceString] is the total for 12 months — this is what
  /// actually lets someone compare it against the monthly package's price.
  /// Null for anything already billed monthly (nothing to divide).
  String? get _monthlyEquivalent {
    final product = package.storeProduct;
    if (product.subscriptionPeriod != 'P1Y') return null;
    final perMonth = product.price / 12;
    final formatted = NumberFormat.simpleCurrency(name: product.currencyCode)
        .format(perMonth);
    return PaymentStrings.storeMonthlyEquivalent(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final monthlyEquivalent = _monthlyEquivalent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeOutCubic,
        scale: selected ? 1.012 : 1,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(selected ? 1.5 : 1),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.journeyPrimary : null,
            color: selected ? null : AppColors.border,
            borderRadius: BorderRadius.circular(21),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppGradients.journeyRoseVioletColors.last
                          .withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: AnimatedContainer(
            duration: _duration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: selected
                  ? Color.alphaBlend(
                      AppGradients.journeyRoseVioletColors.last
                          .withValues(alpha: 0.07),
                      AppColors.card,
                    )
                  : AppColors.card,
              borderRadius: BorderRadius.circular(19.5),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: _duration,
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: selected ? AppGradients.journeyPrimary : null,
                    color: selected ? null : AppColors.surface,
                    shape: BoxShape.circle,
                    border:
                        selected ? null : Border.all(color: AppColors.border),
                  ),
                  child: AnimatedSwitcher(
                    duration: _duration,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: HugeIcon(
                      key: ValueKey(selected),
                      icon: selected
                          ? HugeIcons.strokeRoundedTick02
                          : HugeIcons.strokeRoundedCircle,
                      color: selected ? Colors.white : AppColors.grey3,
                      size: selected ? 19 : 17,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.journeyInk,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (best) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppGradients.journeyPrimary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                PaymentStrings.mostPopular,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (monthlyEquivalent != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          monthlyEquivalent,
                          style: TextStyle(
                            color: AppColors.grey2,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  package.storeProduct.priceString,
                  style: TextStyle(
                    color: selected
                        ? AppGradients.journeyRoseVioletColors.first
                        : AppColors.journeyInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
