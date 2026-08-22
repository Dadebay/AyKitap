import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/streak_strings.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';

/// [StreakScreen]'s "Aýlyk okaýyş" card — a This/Last month toggle plus the
/// picked month's page/minute totals. Owns the toggle itself: nothing else
/// on the screen needs to know which month is showing.
class StreakMonthlyCard extends StatefulWidget {
  const StreakMonthlyCard({super.key});

  @override
  State<StreakMonthlyCard> createState() => _StreakMonthlyCardState();
}

class _StreakMonthlyCardState extends State<StreakMonthlyCard> {
  bool _showLastMonth = false;

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final month = _showLastMonth ? streak.lastMonth : streak.thisMonth;
    final monthPages = month?.pages ?? 0;
    final monthMinutes = month?.minutes ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(StreakStrings.monthlyReading,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    _MonthToggleChip(
                      label: StreakStrings.thisMonth,
                      selected: !_showLastMonth,
                      onTap: () => setState(() => _showLastMonth = false),
                    ),
                    _MonthToggleChip(
                      label: StreakStrings.lastMonth,
                      selected: _showLastMonth,
                      onTap: () => setState(() => _showLastMonth = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$monthPages',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(StreakStrings.pagesRead,
                        style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                  ],
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(StreakStrings.minutesLabel(monthMinutes),
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(StreakStrings.readingTime,
                        style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MonthToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.grey2,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
