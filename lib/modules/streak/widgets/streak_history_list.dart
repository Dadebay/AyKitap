import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/streak_strings.dart';
import '../../../core/models/streak.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';

String _dayLabel(DateTime date) {
  final today = DateTime.now();
  final isToday = date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
  if (isToday) return StreakStrings.today;
  if (isYesterday) return StreakStrings.yesterday;
  return '${date.day} ${StreakStrings.month(date.month)}';
}

/// [StreakScreen]'s "Okaýyş taryhy" section — heading, the day-by-day list
/// (with its own loading/empty states) and a "Has köp" load-more button.
class StreakHistoryList extends StatelessWidget {
  const StreakHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(StreakStrings.readingHistory,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (streak.history.isEmpty && streak.historyLoading)
          _EmptyCard(child: CircularProgressIndicator(color: AppColors.primary))
        else if (streak.history.isEmpty)
          _EmptyCard(
              child: Text(StreakStrings.noReadDaysYet,
                  style: TextStyle(color: AppColors.grey2, fontSize: 13)))
        else
          _HistoryRows(streak.history),
        if (streak.historyHasMore && streak.history.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LoadMoreButton(
              loading: streak.historyLoading,
              onPressed: streak.loadMoreHistory),
        ],
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final Widget child;
  const _EmptyCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Center(child: child),
    );
  }
}

class _HistoryRows extends StatelessWidget {
  final List<StreakDay> days;
  const _HistoryRows(this.days);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: days.asMap().entries.map((entry) {
          final isLast = entry.key == days.length - 1;
          final day = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (day.goalMet ? AppColors.primary : AppColors.grey3)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: day.goalMet
                          ? HugeIcons.strokeRoundedFire
                          : HugeIcons.strokeRoundedBookOpen01,
                      color: day.goalMet ? AppColors.primary : AppColors.grey2,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_dayLabel(day.date),
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Text(StreakStrings.pagesLabel(day.pages),
                    style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
                const SizedBox(width: 10),
                Text(StreakStrings.minutesLabel(day.minutes),
                    style: TextStyle(color: AppColors.grey2, fontSize: 12.5)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _LoadMoreButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.grey2))
            : Text(StreakStrings.loadMore,
                style: TextStyle(
                    color: AppColors.grey1,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}
