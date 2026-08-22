import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/tariff.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';

/// A selectable plan row for one [Tariff]. Selection is driven entirely by
/// implicit animations (border, glow, background tint, icon crossfade,
/// price emphasis) so tapping a different plan reads as a deliberate
/// transition rather than an instant style swap.
class PlanCard extends StatelessWidget {
  final Tariff tariff;
  final String label;
  final bool best;
  final bool selected;
  final VoidCallback onTap;
  const PlanCard({
    super.key,
    required this.tariff,
    required this.label,
    this.best = false,
    required this.selected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeOut,
        scale: selected ? 1.02 : 1.0,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : const [],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: HugeIcon(
                  key: ValueKey(selected),
                  icon: selected
                      ? HugeIcons.strokeRoundedCheckmarkCircle01
                      : HugeIcons.strokeRoundedCircle,
                  color: selected ? AppColors.primary : AppColors.grey3,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: _duration,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.white,
                        fontFamily: 'Gilroy',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      child: Text(label),
                    ),
                    if (best) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(PaymentStrings.mostPopular,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.grey2,
                            decorationThickness: 1.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('-${tariff.discountPercent}%',
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: _duration,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.white,
                      fontFamily: 'Gilroy',
                      fontSize: selected ? 17 : 16,
                      fontWeight: FontWeight.w800,
                    ),
                    child: Text(PaymentStrings.manat(tariff.price)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
