import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../localization/strings/common_strings.dart';

/// Duolingo-style week strip (TZ 8.3 / 9.2): one disc per weekday, Mon..Sun.
/// Read days (≥15 min goal met) are filled with a flame tick; today gets a
/// ring; past unread days are hollow; future days are dimmed.
class StreakWeekRow extends StatelessWidget {
  /// Mon..Sun, true where the daily reading goal was met.
  final List<bool> weekRead;
  final double circleSize;

  const StreakWeekRow({super.key, required this.weekRead, this.circleSize = 36});

  @override
  Widget build(BuildContext context) {
    final letters = CommonStrings.weekdayLetters;
    final todayIndex = DateTime.now().weekday - 1; // 0 = Monday
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final read = weekRead[i];
        final isToday = i == todayIndex;
        final isFuture = i > todayIndex;
        return Column(
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: read ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: AppColors.primary, width: 2)
                    : (read ? null : Border.all(color: AppColors.border)),
              ),
              child: Center(
                child: read
                    ? Text('🔥', style: TextStyle(fontSize: circleSize * 0.5))
                    : (isToday
                        ? Icon(Icons.circle, color: AppColors.primary.withValues(alpha: 0.5), size: circleSize * 0.28)
                        : null),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              letters[i],
              style: TextStyle(
                color: isToday ? AppColors.primary : (isFuture ? AppColors.grey3 : AppColors.grey2),
                fontSize: 11,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}
