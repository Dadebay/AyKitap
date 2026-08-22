import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/streak_strings.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';

/// [StreakScreen]'s explainer row — the daily goal and reward rules spelled
/// out in one sentence.
class StreakInfoCard extends StatelessWidget {
  const StreakInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: AppColors.grey2,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              StreakStrings.streakInfo(
                  streak.goalMinMinutes, streak.rewardRules),
              style:
                  TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
