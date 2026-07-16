import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/widgets/icon_circle_button.dart';
import '../../../core/widgets/streak_flame.dart';

/// The top-of-Home row: "Welcome, {name}" + the current streak pill +
/// the notifications bell.
class HomeHeader extends StatelessWidget {
  const HomeHeader(
      {super.key,
      required this.name,
      required this.onStreakTap,
      required this.onNotificationsTap});

  final String name;
  final VoidCallback onStreakTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: HomeStrings.welcomePrefix,
                      style: TextStyle(color: AppColors.grey2, fontSize: 18)),
                  TextSpan(
                      text: name,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _StreakPill(
              days: context.watch<StreakService>().currentStreak,
              onTap: onStreakTap),
          IconCircleButton(
              icon: HugeIcons.strokeRoundedNotification01,
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int days;
  final VoidCallback? onTap;
  const _StreakPill({required this.days, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.only(left: 4, right: 16),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StreakFlame(size: 30),
            const SizedBox(width: 3),
            Text('$days',
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
