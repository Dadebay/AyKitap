import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings/home_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/daily_reading_goal_service.dart';
import '../../../core/theme/app_colors.dart';
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
    final minutes = goal.secondsToday ~/ 60;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.auto_stories_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(HomeStrings.dailyReadingGoalTitle,
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700))),
                Text('$minutes / 10 ${HomeStrings.minutesShort}',
                    style: TextStyle(color: AppColors.grey2, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: Text(
                        goal.completed
                            ? HomeStrings.dailyReadingGoalDone
                            : HomeStrings.dailyReadingGoalHint,
                        style:
                            TextStyle(color: AppColors.grey2, fontSize: 12))),
                TextButton(
                  onPressed: () => _continue(context),
                  child: Text(HomeStrings.continueReading,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
