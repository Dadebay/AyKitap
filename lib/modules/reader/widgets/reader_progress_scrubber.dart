import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';

/// The page scrubber shared by [ReaderBottomBar] and [PdfBottomBar]: a page
/// number, a slider, and the total page count.
///
/// The slider's [onSeek] is expensive — a real epub.js repagination or a
/// PDFium/PageView page jump — so firing it on every drag frame (as a plain
/// `Slider.onChanged` wired straight to it used to) is what made dragging feel
/// like it stuttered badly. Instead the thumb tracks the drag locally and
/// cheaply via [onChanged], and the real seek only fires once the drag ends —
/// the same pattern any slider over an expensive operation uses (a video
/// scrubber, for instance).
class ReaderProgressScrubber extends StatefulWidget {
  final double progress;
  final int currentPage;
  final int totalPages;
  final Color labelColor;
  final Color activeColor;
  final Color inactiveTrackColor;
  final Color overlayColor;
  final ValueChanged<double> onSeek;

  const ReaderProgressScrubber({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    required this.labelColor,
    required this.activeColor,
    required this.inactiveTrackColor,
    required this.overlayColor,
    required this.onSeek,
  });

  @override
  State<ReaderProgressScrubber> createState() => _ReaderProgressScrubberState();
}

class _ReaderProgressScrubberState extends State<ReaderProgressScrubber> {
  // Non-null while the reader is actively dragging, and for the brief window
  // afterwards while the real page jump this drag triggered is still in
  // flight — see didUpdateWidget.
  double? _dragValue;

  // Safety net for didUpdateWidget's exact-match check below: the engine's
  // own page math (epub.js locations, or a PDF/CBZ page index) doesn't always
  // land on precisely the page this linear estimate predicts, so relying on
  // an exact match alone could leave the thumb pinned at the drag position
  // forever. This forces it to release after a beat regardless.
  Timer? _releaseFallback;

  @override
  void dispose() {
    _releaseFallback?.cancel();
    super.dispose();
  }

  int _pageFor(double value) {
    if (widget.totalPages <= 0) return widget.currentPage;
    return 1 + (value * (widget.totalPages - 1)).round();
  }

  @override
  void didUpdateWidget(covariant ReaderProgressScrubber old) {
    super.didUpdateWidget(old);
    // Once the real navigation this drag triggered has landed — currentPage
    // now matches where the thumb was released — drop back to tracking the
    // real progress. Clearing this the instant the drag ends instead would
    // snap the thumb back to the pre-drag position for the gap between
    // release and the relocation event actually arriving.
    final drag = _dragValue;
    if (drag != null && widget.currentPage == _pageFor(drag)) {
      _releaseFallback?.cancel();
      _dragValue = null;
    }
  }

  void _onChangeEnd(double value) {
    widget.onSeek(value);
    _releaseFallback?.cancel();
    _releaseFallback = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _dragValue = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final drag = _dragValue;
    final value = (drag ?? widget.progress).clamp(0.0, 1.0);
    final reduceMotion = AppMotion.reduceMotion(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: drag != null || reduceMotion
          ? Duration.zero
          : AppMotion.readerProgress,
      curve: AppMotion.easeOut,
      builder: (context, animatedValue, child) {
        final displayedPage =
            drag == null ? widget.currentPage : _pageFor(drag);
        return Row(
          children: [
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppMotion.quick,
              child: Text(
                '$displayedPage',
                key: ValueKey(displayedPage),
                style: TextStyle(color: widget.labelColor, fontSize: 11),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: widget.activeColor,
                  inactiveTrackColor: widget.inactiveTrackColor,
                  thumbColor: widget.activeColor,
                  overlayColor: widget.overlayColor,
                ),
                child: Slider(
                  value: animatedValue.clamp(0.0, 1.0),
                  // Cheap — just repaints the thumb and page-number label.
                  onChanged: (v) => setState(() => _dragValue = v),
                  // The expensive real page jump fires only on release.
                  onChangeEnd: _onChangeEnd,
                ),
              ),
            ),
            Text('${widget.totalPages}',
                style: TextStyle(color: widget.labelColor, fontSize: 11)),
          ],
        );
      },
    );
  }
}
