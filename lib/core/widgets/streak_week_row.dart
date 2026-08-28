import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../localization/strings/common_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  )..value = 1;
  int? _celebratingIndex;

  @override
  void didUpdateWidget(covariant StreakWeekRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.weekRead, widget.weekRead)) return;
    for (var i = 0; i < 7; i++) {
      if (!oldWidget.weekRead[i] && widget.weekRead[i]) {
        _celebratingIndex = i;
        if (AppMotion.reduceMotion(context)) {
          _controller.value = 1;
        } else {
          _controller.forward(from: 0);
        }
        break;
      }
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
    final flameScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.12), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 45),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
    ));
    // The flame's own quick rise-and-fade-in, separate from the whole
    // circle's slower bounce above — it settles well before the bounce does,
    // so the flame reads as arriving first and the circle as catching up.
    final flameEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final read = widget.weekRead[i];
          final isToday = i == todayIndex;
          final isFuture = i > todayIndex;
          final celebrating = read && i == _celebratingIndex;
          final ringSweep = isToday && celebrating
              ? Curves.easeOut.transform(_controller.value)
              : 1.0;
          Widget flame =
              Text('🔥', style: TextStyle(fontSize: widget.circleSize * 0.5));
          if (celebrating) {
            flame = Opacity(
              opacity: flameEntrance.value,
              child: Transform.translate(
                offset: Offset(
                    0, (1 - flameEntrance.value) * widget.circleSize * 0.25),
                child: flame,
              ),
            );
          }
          return Column(
            children: [
              SizedBox(
                width: widget.circleSize,
                height: widget.circleSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (celebrating)
                      ..._buildParticles(widget.circleSize, _controller.value),
                    Transform.scale(
                      scale: celebrating ? flameScale.value : 1,
                      child: Container(
                        width: widget.circleSize,
                        height: widget.circleSize,
                        decoration: BoxDecoration(
                          color: read ? AppColors.primary : AppColors.surface,
                          shape: BoxShape.circle,
                          border: isToday
                              ? null
                              : (read
                                  ? null
                                  : Border.all(color: AppColors.border)),
                        ),
                        child: Center(
                          child: read
                              ? flame
                              : (isToday
                                  ? Icon(Icons.circle,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.5),
                                      size: widget.circleSize * 0.28)
                                  : null),
                        ),
                      ),
                    ),
                    if (isToday)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RingSweepPainter(
                            progress: ringSweep,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
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

  List<Widget> _buildParticles(double size, double progress) {
    final travel = Curves.easeOut.transform(progress);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    const offsets = <Offset>[
      Offset(-0.55, -0.55),
      Offset(-0.25, -0.85),
      Offset(0, -0.95),
      Offset(0.25, -0.85),
      Offset(0.55, -0.55),
    ];
    return offsets
        .map(
          (offset) => Transform.translate(
            offset: Offset(
              offset.dx * size * travel,
              offset.dy * size * travel,
            ),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB34D),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

/// Today's ring. A plain circular stroke at rest ([progress] = 1); while
/// [progress] runs 0 → 1 during a celebration it sweeps in clockwise from
/// the top instead of just appearing, so today's day reads as the one that
/// just completed rather than a ring that was already there.
class _RingSweepPainter extends CustomPainter {
  const _RingSweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingSweepPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
