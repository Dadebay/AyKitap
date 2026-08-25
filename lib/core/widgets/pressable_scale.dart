import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_motion.dart';

/// Lightweight press feedback for cards that do not need a Material ripple.
///
/// Scale runs on the compositor, so image-heavy book/author cards do not
/// rebuild while a finger is down. Selection haptics fire only for a
/// completed tap, never for a cancelled drag in a horizontal shelf.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.haptics = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final bool haptics;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _onTap() {
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _onTap,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
        duration: reduceMotion ? Duration.zero : AppMotion.quick,
        curve: AppMotion.easeOut,
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
