import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/streak_strings.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/streak_flame.dart';

/// [StreakScreen]'s top card — the flame plus current/best streak counts.
class StreakSummaryCard extends StatelessWidget {
  const StreakSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const StreakFlame(size: 64),
          const SizedBox(height: 10),
          Text(StreakStrings.currentStreakLabel(streak.currentStreak),
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(StreakStrings.bestStreakLabel(streak.bestStreak),
              style: TextStyle(color: AppColors.grey2, fontSize: 13)),
        ],
      ),
    );
  }
}
