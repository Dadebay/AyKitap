import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Book-opening screen: [book_reading_boy.json] plus a 0→100% readout.
///
/// Used both by [ReaderScreen] (while epub.js parses/paginates a book) and by
/// the PDF opener (while a text-layer PDF is classified and, on first open,
/// converted to its reflow EPUB) — same full-page look either way, rather
/// than a modal dialog floating over the previous screen.
///
/// The underlying load exposes no byte-level progress, so there's nothing
/// genuine to report — the percentage below is a timed ramp, not a
/// measurement. It eases up to 92% over ~3s and holds there for however long
/// the real load takes, then snaps to 100% the moment [loaded] actually turns
/// true, holds briefly so the number is readable, and calls [onDone].
class BookOpeningOverlay extends StatefulWidget {
  final Color bgColor;
  final bool loaded;
  final VoidCallback onDone;

  const BookOpeningOverlay({
    super.key,
    required this.bgColor,
    required this.loaded,
    required this.onDone,
  });

  @override
  State<BookOpeningOverlay> createState() => _BookOpeningOverlayState();
}

class _BookOpeningOverlayState extends State<BookOpeningOverlay>
    with SingleTickerProviderStateMixin {
  static const _rampCeiling = 0.92;
  static const _rampDuration = Duration(milliseconds: 3200);
  static const _finishDuration = Duration(milliseconds: 260);
  static const _holdAt100 = Duration(milliseconds: 400);

  late final AnimationController _controller;
  late Animation<double> _percent;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _rampDuration);
    _percent = Tween<double>(begin: 0, end: _rampCeiling).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    if (widget.loaded) _finish();
  }

  @override
  void didUpdateWidget(covariant BookOpeningOverlay old) {
    super.didUpdateWidget(old);
    if (widget.loaded && !old.loaded) _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final start = _percent.value;
    _controller
      ..stop()
      ..duration = _finishDuration;
    _percent = Tween<double>(begin: start, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.value = 0;
    await _controller.forward();
    await Future.delayed(_holdAt100);
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.bgColor.computeLuminance() < 0.4;
    final fg = isDark ? Colors.white : Colors.black87;
    final fgMuted = isDark ? Colors.white54 : Colors.black45;

    return Container(
      color: widget.bgColor,
      child: Center(
        child: AnimatedBuilder(
          animation: _percent,
          builder: (context, _) {
            final shown = (_percent.value * 100).round().clamp(0, 100);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.asset(
                    'assets/animations/book_reading_boy.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$shown%',
                  style: TextStyle(
                      color: fg, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _percent.value,
                      minHeight: 5,
                      backgroundColor: fgMuted.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ReaderStrings.bookOpening,
                  style: TextStyle(color: fgMuted, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
