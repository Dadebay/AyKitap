import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../localization/strings/common_strings.dart';

/// Duolingo-style week strip (TZ 8.3 / 9.2): one disc per weekday, Mon..Sun.
/// Read days (≥15 min goal met) are filled with a flame tick; today gets a
/// ring; past unread days are hollow; future days are dimmed.
class StreakWeekRow extends StatefulWidget {
  /// Mon..Sun, true where the daily reading goal was met.
  final List<bool> weekRead;
  final double circleSize;

  const StreakWeekRow(
      {super.key, required this.weekRead, this.circleSize = 36});

  @override
  State<StreakWeekRow> createState() => _StreakWeekRowState();
}

class _StreakWeekRowState extends State<StreakWeekRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _motionConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.celebration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionConfigured) return;
    _motionConfigured = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant StreakWeekRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.weekRead, widget.weekRead)) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = CommonStrings.weekdayLetters;
    final todayIndex = DateTime.now().weekday - 1; // 0 = Monday
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final read = widget.weekRead[i];
          final isToday = i == todayIndex;
          final isFuture = i > todayIndex;
          final start = i * 0.065;
          final end = (start + 0.58).clamp(0.0, 1.0);
          final reveal = read
              ? CurvedAnimation(
                  parent: _controller,
                  curve: Interval(start, end, curve: AppMotion.easeOut),
                ).value
              : 1.0;
          return Column(
            children: [
              Transform.scale(
                scale: read ? 0.72 + (0.28 * reveal) : 1,
                child: Opacity(
                  opacity: reveal,
                  child: Container(
                    width: widget.circleSize,
                    height: widget.circleSize,
                    decoration: BoxDecoration(
                      color: read ? AppColors.primary : AppColors.surface,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : (read ? null : Border.all(color: AppColors.border)),
                    ),
                    child: Center(
                      child: read
                          ? Text('🔥',
                              style:
                                  TextStyle(fontSize: widget.circleSize * 0.5))
                          : (isToday
                              ? Icon(Icons.circle,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  size: widget.circleSize * 0.28)
                              : null),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                letters[i],
                style: TextStyle(
                  color: isToday
                      ? AppColors.primary
                      : (isFuture ? AppColors.grey3 : AppColors.grey2),
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
