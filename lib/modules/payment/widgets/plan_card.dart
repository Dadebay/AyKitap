import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/models/tariff.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Premium selectable plan with a gradient selection frame. The outer frame
/// animates without changing layout, so switching plans stays calm and clear.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.tariff,
    required this.label,
    this.best = false,
    required this.selected,
    required this.onTap,
  });

  final Tariff tariff;
  final String label;
  final bool best;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 220);

  String get _monthlyPrice {
    final monthly = tariff.price / tariff.monthCount;
    final num amount = monthly == monthly.roundToDouble()
        ? monthly.toInt()
        : double.parse(monthly.toStringAsFixed(1));
    return PaymentStrings.monthlyEquivalent(amount);
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 5),
                      Text(
                        _monthlyPrice,
                        style: TextStyle(
                          color: AppColors.grey2,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tariff.hasDiscount) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            PaymentStrings.manat(tariff.actualPrice!),
                            style: TextStyle(
                              color: AppColors.grey2,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.grey2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C7D)
                                  .withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '-${tariff.discountPercent}%',
                              style: const TextStyle(
                                color: Color(0xFFE84C70),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      PaymentStrings.manat(tariff.price),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
