import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/tariff.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/payment_strings.dart';
import '../subscription_plan_helpers.dart';
import 'plan_card.dart';

/// [SubscriptionScreen]'s plan list — loading/error states, then a
/// [PlanCard] per tariff with the best-value one badged.
class SubscriptionPlanList extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Tariff> tariffs;
  final int selected;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelect;

  const SubscriptionPlanList({
    super.key,
    required this.loading,
    required this.error,
    required this.tariffs,
    required this.selected,
    required this.onRetry,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final error = this.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(PaymentStrings.tariffsLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey2, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onRetry,
                child: Text(PaymentStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      );
    }
    final bestIndex = tariffs.isEmpty ? -1 : bestSubscriptionPlanIndex(tariffs);
    return Column(
      children: tariffs.asMap().entries.map((entry) {
        final i = entry.key;
        final tariff = entry.value;
        final isSelected = selected == i;
        return PlanCard(
          tariff: tariff,
          label: subscriptionPlanLabel(tariff),
          best: i == bestIndex && tariff.discountPercent > 0,
          selected: isSelected,
          onTap: () {
            if (isSelected) return;
            HapticFeedback.selectionClick();
            onSelect(i);
          },
        );
      }).toList(),
    );
  }
}
