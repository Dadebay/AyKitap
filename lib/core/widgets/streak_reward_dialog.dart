import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/streak.dart';
import '../theme/app_colors.dart';
import '../localization/strings/streak_strings.dart';

/// Congratulation dialog shown when a `POST /streaks/report` response comes
/// back with a non-empty `rewards[]` — [StreakService] is the only caller,
/// right after it applies the reward to local state.
class StreakRewardDialog extends StatelessWidget {
  final StreakReward reward;
  const StreakRewardDialog({super.key, required this.reward});

  static Future<void> show(BuildContext context, StreakReward reward) {
    return showDialog<void>(
      context: context,
      builder: (_) => StreakRewardDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBalance = reward.rewardType == StreakRewardType.balance;
    final message = isBalance
        ? StreakStrings.rewardBalanceMessage(
            reward.amount ?? 0, reward.streakDay)
        : StreakStrings.rewardSubscriptionMessage(
            reward.monthCount ?? 1, reward.streakDay);
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Center(
                child: HugeIcon(
                  icon: isBalance
                      ? HugeIcons.strokeRoundedCoins01
                      : HugeIcons.strokeRoundedCrown,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(StreakStrings.rewardTitle,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey1, fontSize: 14, height: 1.4)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(StreakStrings.rewardCta,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
