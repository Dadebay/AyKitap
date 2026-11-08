import 'dart:async';

import 'package:flutter/material.dart';

import '../localization/strings/streak_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Non-blocking, one-shot feedback for the false → true daily-goal change.
class StreakGoalCelebration extends StatefulWidget {
  const StreakGoalCelebration({
    super.key,
    required this.minutes,
    required this.pages,
    required this.onFinished,
  });

  final int minutes;
  final int pages;
  final VoidCallback onFinished;

  static void show(
    BuildContext context, {
    required int minutes,
    required int pages,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => StreakGoalCelebration(
        minutes: minutes,
        pages: pages,
        onFinished: entry.remove,
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<StreakGoalCelebration> createState() => _StreakGoalCelebrationState();
}

class _StreakGoalCelebrationState extends State<StreakGoalCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    reverseDuration: AppMotion.quick,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut,
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 14,
      left: 18,
      right: 18,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(curved),
            child: Material(
              color: AppColors.card,
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔥', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StreakStrings.goalCompletedTitle,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            StreakStrings.goalCompletedBody(
                              widget.minutes,
                              widget.pages,
                            ),
                            style: TextStyle(
                              color: AppColors.grey2,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
