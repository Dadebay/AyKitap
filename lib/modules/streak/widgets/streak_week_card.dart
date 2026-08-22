import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/streak_strings.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/streak_week_row.dart';

/// [StreakScreen]'s "Bu hepde" card — the same week grid [ProfileScreen]'s
/// card shows, just bigger circles.
class StreakWeekCard extends StatelessWidget {
  const StreakWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(StreakStrings.thisWeek,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          StreakWeekRow(weekRead: streak.weekRead, circleSize: 38),
        ],
      ),
    );
  }
}
