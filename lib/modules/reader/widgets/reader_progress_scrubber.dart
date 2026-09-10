import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';

/// The progress scrubber shared by [ReaderBottomBar] and [PdfBottomBar]: a
/// position label, a slider, and the end-of-range label.
///
/// A PDF or CBZ has real, fixed pages, so it reads "12 —————— 240". An EPUB
/// does not: reflowable text has no inherent pages, so epub.js's page count
/// is derived by measuring how much text a screen currently holds — which
/// legitimately differs with font size, orientation, and even which screens
/// happened to be sampled while warming up. The same book could open as
/// 17/153 one session and the same spot read 14/131 the next, which looks
/// broken even when the reader is exactly where they left off. So an EPUB
/// shows the one figure that *is* stable across sessions — the percentage
/// through the book, straight from epub.js's locations. See [showPercentage].
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

  /// Label the position as a percentage of the book rather than as
  /// "page / total". Set for the EPUB reader, whose page count isn't stable
  /// enough to show — see this class's own doc comment. [currentPage] and
  /// [totalPages] are then unused.
  final bool showPercentage;

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
    this.showPercentage = false,
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

  // The value the label is showing (a page number, or a percentage in
  // [ReaderProgressScrubber.showPercentage] mode), and a counter that ticks
  // once per actual change.
  //
  // The AnimatedSwitcher below is keyed by the *counter*, not by the page
  // number, because it keeps an outgoing child mounted for the whole fade and
  // does not deduplicate that child against the incoming one. Scrolling a PDF
  // crosses a page boundary back and forth well inside those 180ms, so the
  // page number could return to a value whose previous label was still fading
  // out — leaving the switcher's Stack holding two children with an identical
  // ValueKey(page), which throws "Duplicate keys found" and takes the reader
  // down. A counter only ever moves forward, so no two live children can
  // collide; and because it ticks only when the number really changes, an
  // unchanged page still keeps its key and doesn't re-animate when something
  // unrelated rebuilds this widget.
  late int _labelValue;
  int _labelSeq = 0;

  @override
  void initState() {
    super.initState();
    _labelValue = _displayedValue;
  }

  @override
  void dispose() {
    _releaseFallback?.cancel();
    super.dispose();
  }

  int _pageFor(double value) {
    if (widget.totalPages <= 0) return widget.currentPage;
    return 1 + (value * (widget.totalPages - 1)).round();
  }

  /// What the left-hand label reads: a whole percentage of the book in
  /// [ReaderProgressScrubber.showPercentage] mode, otherwise a page number.
  /// While dragging it follows the thumb; otherwise it follows where the
  /// reader really is.
  int get _displayedValue {
    final drag = _dragValue;
    if (widget.showPercentage) {
      return ((drag ?? widget.progress).clamp(0.0, 1.0) * 100).round();
    }
    return drag == null ? widget.currentPage : _pageFor(drag);
  }

  /// Whether the real navigation a released drag triggered has landed — the
  /// cue to stop pinning the thumb to the drag position (see
  /// [didUpdateWidget]). Percentage mode has no page number to match on, so
  /// it compares the progress itself.
  bool _seekLanded(double drag) => widget.showPercentage
      ? (widget.progress - drag).abs() < 0.01
      : widget.currentPage == _pageFor(drag);

  /// Moves the label on to [_displayedValue], bumping [_labelSeq] only when
  /// it genuinely changed. Call after anything that can move the label — new
  /// progress/page from the parent, or a change to [_dragValue].
  void _syncLabel() {
    final value = _displayedValue;
    if (value == _labelValue) return;
    _labelValue = value;
    _labelSeq++;
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
    if (drag != null && _seekLanded(drag)) {
      _releaseFallback?.cancel();
      _dragValue = null;
    }
    _syncLabel();
  }

  void _onChangeEnd(double value) {
    widget.onSeek(value);
    _releaseFallback?.cancel();
    _releaseFallback = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _dragValue = null;
          _syncLabel();
        });
      }
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
        return Row(
          children: [
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppMotion.quick,
              child: Text(
                widget.showPercentage ? '%$_labelValue' : '$_labelValue',
                key: ValueKey(_labelSeq),
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
                  onChanged: (v) => setState(() {
                    _dragValue = v;
                    _syncLabel();
                  }),
                  // The expensive real page jump fires only on release.
                  onChangeEnd: _onChangeEnd,
                ),
              ),
            ),
            // Omitted in percentage mode: the left label already says how far
            // through the book the reader is, and a fixed "%100" on the right
            // would only take room from the track.
            if (!widget.showPercentage)
              Text('${widget.totalPages}',
                  style: TextStyle(color: widget.labelColor, fontSize: 11)),
          ],
        );
      },
    );
  }
}
