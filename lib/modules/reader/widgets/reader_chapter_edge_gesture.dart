import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Long-press and swipe upward on the middle of the right edge to rush to
/// the next EPUB chapter. The narrow target leaves text selection untouched.
class ReaderChapterEdgeGesture extends StatefulWidget {
  const ReaderChapterEdgeGesture({
    super.key,
    required this.onNextChapter,
    required this.isDarkPage,
  });

  final VoidCallback onNextChapter;
  final bool isDarkPage;

  @override
  State<ReaderChapterEdgeGesture> createState() =>
      _ReaderChapterEdgeGestureState();
}

class _ReaderChapterEdgeGestureState extends State<ReaderChapterEdgeGesture> {
  double _startY = 0;
  bool _held = false;
  bool _triggered = false;

  void _start(LongPressStartDetails details) {
    setState(() {
      _startY = details.globalPosition.dy;
      _held = true;
      _triggered = false;
    });
  }

  void _move(LongPressMoveUpdateDetails details) {
    if (!_held || _triggered) return;
    if (_startY - details.globalPosition.dy < 36) return;
    setState(() => _triggered = true);
    widget.onNextChapter();
  }

  void _end() {
    if (mounted && _held) setState(() => _held = false);
  }

  @override
  Widget build(BuildContext context) {
    final handleColor = widget.isDarkPage ? Colors.white38 : Colors.black38;
    return SizedBox(
      width: 38,
      height: 252,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: _start,
        onLongPressMoveUpdate: _move,
        onLongPressEnd: (_) => _end(),
        onLongPressCancel: _end,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Container(
              width: 3,
              height: 38,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (_held)
              Positioned(
                right: 9,
                child: IgnorePointer(
                  child: Container(
                    width: 28,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xEB1C1C27),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      _triggered
                          ? Icons.check_rounded
                          : Icons.keyboard_double_arrow_up_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
