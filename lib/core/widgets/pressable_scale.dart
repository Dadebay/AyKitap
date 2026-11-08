import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

/// Lightweight press feedback for cards that do not need a Material ripple.
///
/// Scale runs on the compositor, so image-heavy book/author cards do not
/// rebuild while a finger is down. Selection haptics fire only for a
/// completed tap, never for a cancelled drag in a horizontal shelf. The
/// press-down and release legs use different durations ([AppMotion.pressDown]
/// / [AppMotion.pressRelease]) so the down reaction feels immediate while the
/// release feels settled — a single symmetric duration read as mushy in both
/// directions.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptics;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pressDown,
    reverseDuration: AppMotion.pressRelease,
  );
  late final Animation<double> _scale = _controller.drive(
    Tween<double>(begin: 1, end: widget.pressedScale)
        .chain(CurveTween(curve: AppMotion.easeOut)),
  );

  // Cached rather than read from `context` inside `_setPressed`: a gesture
  // recognizer's own teardown can still fire `onTapCancel` while its
  // element is deactivating (e.g. the widget is torn down mid-press), and
  // an inherited-widget lookup on a deactivated element throws. Reading it
  // here in `didChangeDependencies` — always called while active — is the
  // same fix `StaggerFadeIn`/`StreakGoalCelebration` use for the same reason.
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotion(context);
  }

  void _setPressed(bool pressed) {
    if (_reduceMotion) return;
    if (pressed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onTap() {
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
