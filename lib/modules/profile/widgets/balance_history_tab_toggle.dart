import 'package:flutter/cupertino.dart' show CupertinoSlidingSegmentedControl;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum BalanceTab { history, cardPayments }

/// [BalanceScreen]'s history/card-payments segmented toggle.
class BalanceHistoryTabToggle extends StatelessWidget {
  final BalanceTab selected;
  final String historyLabel;
  final String cardPaymentsLabel;
  final ValueChanged<BalanceTab> onChanged;

  const BalanceHistoryTabToggle({
    super.key,
    required this.selected,
    required this.historyLabel,
    required this.cardPaymentsLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 12) / 2;
        return CupertinoSlidingSegmentedControl<BalanceTab>(
          groupValue: selected,
          backgroundColor: AppColors.card,
          thumbColor: AppColors.primary,
          padding: const EdgeInsets.all(3),
          onValueChanged: (tab) {
            if (tab != null && tab != selected) onChanged(tab);
          },
          children: {
            BalanceTab.history:
                _tabLabel(historyLabel, BalanceTab.history, segmentWidth),
            BalanceTab.cardPayments: _tabLabel(
                cardPaymentsLabel, BalanceTab.cardPayments, segmentWidth),
          },
        );
      },
    );
  }

  Widget _tabLabel(String label, BalanceTab tab, double width) {
    final isSelected = selected == tab;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.grey2,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
