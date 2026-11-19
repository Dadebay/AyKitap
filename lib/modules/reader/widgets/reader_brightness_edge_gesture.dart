import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A narrow long-press target at the middle of the left edge. A vertical
/// drag changes brightness without turning pages or covering the book.
class ReaderBrightnessEdgeGesture extends StatefulWidget {
  const ReaderBrightnessEdgeGesture({
    super.key,
    required this.brightness,
    required this.onChanged,
    required this.isDarkPage,
  });

  final double brightness;
  final ValueChanged<double> onChanged;
  final bool isDarkPage;

  @override
  State<ReaderBrightnessEdgeGesture> createState() =>
      _ReaderBrightnessEdgeGestureState();
}

class _ReaderBrightnessEdgeGestureState
    extends State<ReaderBrightnessEdgeGesture> {
  static const _dragRange = 220.0;
  double _startY = 0;
  double _startValue = 1;
  double _value = 1;
  double _lastSent = -1;
  bool _active = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _start(LongPressStartDetails details) {
    _hideTimer?.cancel();
    setState(() {
      _startY = details.globalPosition.dy;
      _startValue = widget.brightness.clamp(0.1, 1.0);
      _value = _startValue;
      _lastSent = _startValue;
      _active = true;
    });
  }

  void _move(LongPressMoveUpdateDetails details) {
    if (!_active) return;
    final next =
        (_startValue + (_startY - details.globalPosition.dy) / _dragRange)
            .clamp(0.1, 1.0);
    if ((next - _value).abs() < 0.005) return;
    setState(() => _value = next);
    if ((next - _lastSent).abs() >= 0.03) {
      _lastSent = next;
      widget.onChanged(next);
    }
  }

  void _end() {
    if (!_active) return;
    widget.onChanged(_value);
    _hideTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final handleColor = widget.isDarkPage ? Colors.white38 : Colors.black38;
    return SizedBox(
      width: 122,
      height: 252,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          SizedBox(
            width: 34,
            height: 252,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: _start,
              onLongPressMoveUpdate: _move,
              onLongPressEnd: (_) => _end(),
              onLongPressCancel: _end,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          if (_active)
            Positioned(
              left: 42,
              top: 31,
              child: IgnorePointer(
                child: Container(
                  width: 60,
                  height: 190,
                  padding: const EdgeInsets.fromLTRB(8, 11, 8, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xEB1C1C27),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wb_sunny_rounded,
                          color: Colors.white, size: 17),
                      const SizedBox(height: 7),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: LinearProgressIndicator(
                            value: (_value - 0.1) / 0.9,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(5),
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text('${(_value * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
