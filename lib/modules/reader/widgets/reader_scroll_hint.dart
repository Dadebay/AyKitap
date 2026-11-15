import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// One-time coachmark shown the first time the reader opens, telling the
/// reader which way pages move: swipe up/down for the (default) scroll
/// transition, left/right for the paged ones. Dismissed by a tap or after a
/// few seconds, and never shown again once seen.
class ReaderScrollHint extends StatefulWidget {
  const ReaderScrollHint({
    super.key,
    required this.enabled,
    required this.vertical,
    required this.kind,
  });

  /// Which reader this is ('epub', 'pdf', 'cbz') — each one shows the hint
  /// once on its own.
  final String kind;

  /// True once the book is actually on screen (opening overlay gone).
  final bool enabled;

  /// True when pages turn with a vertical swipe.
  final bool vertical;

  String get _prefsKey => 'reader_scroll_hint_seen_v2_$kind';

  @override
  State<ReaderScrollHint> createState() => _ReaderScrollHintState();
}

class _ReaderScrollHintState extends State<ReaderScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _seen = true; // assume seen until prefs say otherwise
  bool _visible = false;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seen = prefs.getBool(widget._prefsKey) ?? false;
    } catch (_) {
      _seen = true; // never nag if storage is unavailable
    }
    _maybeShow();
  }

  @override
  void didUpdateWidget(ReaderScrollHint old) {
    super.didUpdateWidget(old);
    _maybeShow();
  }

  void _maybeShow() {
    if (!mounted || _visible || _seen || !widget.enabled) return;
    setState(() => _visible = true);
    _anim.repeat();
    _autoClose = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!_visible) return;
    _autoClose?.cancel();
    _seen = true;
    if (mounted) setState(() => _visible = false);
    _anim.stop();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget._prefsKey, true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Must stay a Positioned child even when hidden: a plain zero-size child
    // would become the Stack's only non-positioned child and collapse the
    // whole reader Stack to 0x0 under a loose-constraint Scaffold body.
    if (!_visible) {
      return const Positioned(
          left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
    }
    final vertical = widget.vertical;
    return Positioned.fill(
      // Any touch dismisses the hint *and* still reaches the reader below
      // (translucent Listener + IgnorePointer content), so it never blocks
      // reading or feels like a frozen screen.
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _dismiss(),
        child: IgnorePointer(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.55),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: vertical ? 90 : 200,
                      height: vertical ? 200 : 90,
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) =>
                            _buildGesture(_anim.value, vertical),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        vertical
                            ? ReaderStrings.scrollHintVertical
                            : ReaderStrings.scrollHintHorizontal,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ReaderStrings.scrollHintTapToClose,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w400,
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

  /// A finger dot that slides along the swipe axis (up for vertical, left for
  /// horizontal), fading in at the start and out at the end, with arrows
  /// marking both directions of travel.
  Widget _buildGesture(double t, bool vertical) {
    final eased = Curves.easeInOut.transform(t);
    final opacity = t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
    final arrowColor = Colors.white.withValues(alpha: 0.55);
    final icons = vertical
        ? [Icons.keyboard_arrow_up_rounded, Icons.keyboard_arrow_down_rounded]
        : [
            Icons.keyboard_arrow_left_rounded,
            Icons.keyboard_arrow_right_rounded
          ];

    final finger = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.9),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 16,
            ),
          ],
        ),
        child:
            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 24),
      ),
    );

    // Travel: bottom -> top / right -> left (the way a finger moves to go on).
    const travel = 110.0;
    final offset = (0.5 - eased) * travel * 2 * 0.5;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: vertical ? Alignment.topCenter : Alignment.centerLeft,
          child: Icon(icons[0], color: arrowColor, size: 40),
        ),
        Align(
          alignment: vertical ? Alignment.bottomCenter : Alignment.centerRight,
          child: Icon(icons[1], color: arrowColor, size: 40),
        ),
        Transform.translate(
          offset: vertical ? Offset(0, offset) : Offset(offset, 0),
          child: finger,
        ),
      ],
    );
  }
}
