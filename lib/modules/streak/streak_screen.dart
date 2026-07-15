import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/streak_flame.dart';
import '../../core/widgets/streak_week_row.dart';
import '../../core/localization/strings/streak_strings.dart';

String _dayLabel(DateTime date) {
  final today = DateTime.now();
  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  if (isToday) return StreakStrings.today;
  if (isYesterday) return StreakStrings.yesterday;
  return '${date.day} ${StreakStrings.month(date.month)}';
}

/// Full-page view of the reading streak shown as a pill on HomeScreen —
/// same week grid as ProfileScreen's card, plus a per-day reading log
/// (pages + minutes) so a user can see exactly what they read and when.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  @override
  void initState() {
    super.initState();
    StreakService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(StreakStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: StreakService.instance,
        builder: (context, _) {
          final streak = StreakService.instance;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const StreakFlame(size: 64),
                    const SizedBox(height: 10),
                    Text(StreakStrings.currentStreakLabel(streak.currentStreak), style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(StreakStrings.bestStreakLabel(streak.bestStreak), style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(StreakStrings.thisWeek, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    StreakWeekRow(weekRead: streak.weekRead, circleSize: 38),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle, color: AppColors.grey2, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        StreakStrings.streakInfo,
                        style: TextStyle(color: AppColors.grey2, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(StreakStrings.readingHistory, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (streak.history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Text(StreakStrings.noReadDaysYet, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: streak.history.asMap().entries.map((entry) {
                      final isLast = entry.key == streak.history.length - 1;
                      final day = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (day.metGoal ? AppColors.primary : AppColors.grey3).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: HugeIcon(
                                  icon: day.metGoal ? HugeIcons.strokeRoundedFire : HugeIcons.strokeRoundedBookOpen01,
                                  color: day.metGoal ? AppColors.primary : AppColors.grey2,
                                  size: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_dayLabel(day.date), style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                            Text(StreakStrings.pagesLabel(day.pages), style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                            const SizedBox(width: 10),
                            Text(StreakStrings.minutesLabel(day.minutes), style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
