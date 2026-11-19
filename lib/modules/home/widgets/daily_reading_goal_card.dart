import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings/home_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/daily_reading_goal_service.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../library/library_screen.dart';
import '../../reader/views/reader_tab_screen.dart';

class DailyReadingGoalCard extends StatelessWidget {
  const DailyReadingGoalCard({super.key});

  Future<void> _continue(BuildContext context) async {
    final opened = await openLastReadBook(context);
    if (!opened && context.mounted) context.push(const LibraryScreen());
  }

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<DailyReadingGoalService>();
    final streakDays = context.watch<StreakService>().currentStreak;
    final minutes = goal.secondsToday ~/ 60;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _continue(context),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 12, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: goal.progress,
                            strokeWidth: 2.5,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                          Icon(
                            goal.completed
                                ? Icons.check_rounded
                                : Icons.menu_book_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.completed
                                ? HomeStrings.dailyReadingGoalDone
                                : HomeStrings.dailyReadingGoalLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$minutes / ${DailyReadingGoalService.targetSeconds ~/ 60} ${HomeStrings.minutesShort}',
                            style: TextStyle(
                              color: AppColors.grey2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(width: 11),
                    Icon(Icons.local_fire_department_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('$streakDays ${HomeStrings.daysShort}',
                        style: TextStyle(
                            color: AppColors.grey1,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.grey2, size: 18),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 11),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: goal.progress),
                  duration: AppMotion.reduceMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
