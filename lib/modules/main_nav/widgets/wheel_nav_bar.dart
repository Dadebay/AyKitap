import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';

/// A turntable-style nav bar: icons sit on a visible dome (the "disk").
/// Tapping an icon rotates the whole disk like a wheel so that icon rises
/// to the top-centre; the icon leaving the centre curves around to the side.
///
/// The wheel can also be turned by hand: dragging horizontally anywhere over
/// the bar spins it under the finger, and on release it settles onto the
/// nearest slot — whichever icon ends up centred becomes the selected tab.
/// The ring wraps, so spinning past either end carries on into the icons on
/// the other side rather than stopping.
class WheelNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const WheelNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<WheelNavBar> createState() => _WheelNavBarState();
}

class _WheelNavBarState extends State<WheelNavBar> with SingleTickerProviderStateMixin {
  // Profile, Kitaplyk, Ana sayfa (centre), Çytalka (reader), Poisk — must
  // stay in lockstep with _buildPages() in MainNavScreen.
  static const _icons = [
    HugeIcons.strokeRoundedUser,
    HugeIcons.strokeRoundedLibrary,
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedPlay,
    HugeIcons.strokeRoundedSearch01,
  ];

  // ── Geometry ────────────────────────────────────────────────────────────
  static const _barHeight = 42.0;
  static const _fabSize = 56.0;
  static const _iconBoxSize = 40.0;
  // Minimum tappable square per icon — the visible icon can be smaller, this
  // just widens the invisible hit area to a finger-friendly size (~Apple's
  // 44pt guidance, with a little extra).
  static const _minTapTarget = 52.0;

  // The dome and the icon ring share the same centre (diskCenterY = _diskR -
  // _domeLift). Growing _diskR and _domeLift by the same amount enlarges the
  // visible dome circle while keeping that centre — and therefore every
  // icon's position — exactly where it was.
  static const _diskR = 400.0; // radius of the dome — a true circle, not an ellipse
  static const _pathR = 365.0; // radius of the ring the icons travel on — right up against the rim, so unselected icons sit at the dome's outer edge rather than buried near its centre
  // Radius the fully-selected icon rides at — a bit past _pathR so it still
  // pokes out over the rim, but well short of _diskR so it doesn't perch too
  // high above the bar. Lower this to drop the selected icon further down.
  static const _selectedR = 390.0;
  static const _stepRad = 14.0 * math.pi / 220.0; // angle between two icons
  // Keeps diskCenterY (_diskR - _domeLift) at 170, the value that lands the
  // ring in the visible window — must track _diskR so the icons don't drift
  // off-screen when the dome size changes.
  static const _domeLift = 40.0; // how far the dome pokes above the bar's top edge

  // Extra height added on top of the bar purely so the raised dome/icons fall
  // inside the widget's hit-test box (see build). Covers the full dome lift
  // plus a small margin; icons stay put visually, they just become tappable.
  static const _domeHitOverhang = _domeLift + 6;

  // Only icons whose angle from the top is inside this window are drawn.
  // With 5 icons the farthest slot is still 2 steps away (2 * _stepRad ≈
  // 1.40rad, same as with 4), so both bounds must clear that to keep every
  // icon fully opaque at rest.
  static const _windowRad = 1.90;
  static const _fadeStart = 1.60;

  // ── Drag ────────────────────────────────────────────────────────────────
  // How far, horizontally, one slot travels at the top of the ring:
  // d(cx)/d(index) is r·sin'(0)·stepRad = r·stepRad. Converting the finger's
  // dx through this is what makes the icons track the finger 1:1 instead of
  // at some arbitrary made-up rate.
  static const _pxPerStep = _pathR * _stepRad;
  // Past this speed a release counts as a flick: the wheel carries on to the
  // next slot in the direction it was thrown even if the finger never
  // dragged a full one.
  static const _flingVelocity = 320.0; // px/s

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutBack,
  );

  // Where the current settle animation started from. A double (not an index)
  // because a hand-turned wheel is released at an arbitrary angle between
  // two slots, and the settle has to run from exactly there.
  double _fromFloat = 0;

  // The wheel's position while a finger is turning it; null the rest of the
  // time, when [_anim] drives the position instead.
  double? _dragFloat;

  // Nearest slot the last haptic detent fired for, so the tick happens once
  // per slot crossed rather than on every drag frame.
  int? _lastDetent;

  @override
  void initState() {
    super.initState();
    _fromFloat = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(WheelNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      // Re-aim from wherever the wheel actually is right now — mid-settle, or
      // the angle a drag was just released at — rather than from the outgoing
      // index. Without this a turn that lands on a new tab would unwind back
      // to the old icon before animating forward again.
      _fromFloat = _wrap(_dragFloat ?? _selFloatFor(old.selectedIndex));
      _dragFloat = null;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Shortest signed distance on a ring of [n] slots.
  double _circular(double raw, int n) {
    var x = raw % n;
    if (x < 0) x += n;
    if (x > n / 2) x -= n;
    return x;
  }

  /// Folds a position back into `[0, n)`. Rendering already draws each icon's
  /// wrap-around copies, so a wrapped value looks identical on screen — this
  /// just stops the number itself drifting off after many turns, which would
  /// eventually push every icon outside the visible angle window.
  double _wrap(double v) {
    final n = _icons.length;
    var x = v % n;
    if (x < 0) x += n;
    return x;
  }

  /// The wheel's animated position when it's settling toward [selectedIndex].
  double _selFloatFor(int selectedIndex) {
    final delta = _circular(selectedIndex - _fromFloat, _icons.length);
    return _fromFloat + delta * _anim.value;
  }

  void _onDragStart(DragStartDetails _) {
    // Take over from exactly where the settle animation had got to, so
    // grabbing a mid-flight wheel doesn't jump.
    _ctrl.stop();
    setState(() {
      _dragFloat = _selFloatFor(widget.selectedIndex);
      _lastDetent = _dragFloat!.round();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final drag = _dragFloat;
    if (drag == null) return;
    // Dragging left turns the wheel forward — the icon to the right of centre
    // rises into it — which is +1 slot per [_pxPerStep] of leftward travel.
    final next = _wrap(drag - details.delta.dx / _pxPerStep);
    final detent = next.round();
    if (detent != _lastDetent) {
      _lastDetent = detent;
      HapticFeedback.selectionClick();
    }
    setState(() => _dragFloat = next);
  }

  void _onDragEnd(DragEndDetails details) {
    final drag = _dragFloat;
    if (drag == null) return;
    final n = _icons.length;
    final vx = details.velocity.pixelsPerSecond.dx;

    // Nearest slot normally; a flick instead carries the wheel on in the
    // direction it was thrown, so a short-but-fast swipe still changes tab
    // rather than snapping back.
    final slot = vx.abs() >= _flingVelocity ? (vx < 0 ? drag.ceil() : drag.floor()) : drag.round();
    var target = slot % n;
    if (target < 0) target += n;

    setState(() {
      // Settle from the released angle, not from the outgoing tab's slot.
      _fromFloat = drag;
      _dragFloat = null;
      _lastDetent = null;
    });
    // Order matters: the parent's rebuild (and so [didUpdateWidget], which
    // re-aims the settle at the new tab) lands in the same frame as this
    // controller start, while [_anim] is still at 0 — so the wheel picks up
    // from `drag` either way, whether or not the tab actually changed.
    if (target != widget.selectedIndex) widget.onTap(target);
    _ctrl.forward(from: 0);
  }

  void _onDragCancel() {
    final drag = _dragFloat;
    if (drag == null) return;
    setState(() {
      _fromFloat = drag;
      _dragFloat = null;
      _lastDetent = null;
    });
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Use viewPadding (not padding): an ancestor SafeArea already consumed
    // `padding.bottom` for this subtree, which would make it read as 0 even
    // though Android's 3-button nav bar is still there covering the screen.
    // viewPadding is the raw OS inset and isn't zeroed by ancestor SafeAreas.
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final n = _icons.length;
    final centreX = screenWidth / 2;
    // The icons ride on a dome that pokes _domeLift px *above* the bar's top
    // edge. That raised strip used to sit outside the widget's own box, so
    // Flutter never hit-tested it — the upper half of every icon (and almost
    // all of the tall centre icon) was visible but untappable, which is what
    // made the tabs so fiddly to hit on iPhone. We give the widget an extra
    // [_domeHitOverhang] of height on top and shift the whole icon/dome frame
    // down by the same amount: every pixel stays at the exact same screen
    // position (the bar is bottom-anchored, so growing it grows upward), but
    // the raised strip is now inside the box and therefore hit-testable.
    // Nothing here paints a solid background, and the dome CustomPaint doesn't
    // absorb touches, so this added strip still lets taps fall through to the
    // body everywhere except on an actual icon.
    final diskCenterY = _domeHitOverhang + (_diskR - _domeLift);
    final boxTop = _domeHitOverhang - (_domeLift + 2); // +2px so the apex isn't clipped
    final boxHeight = (_barHeight + _domeHitOverhang) - boxTop;

    return SizedBox(
      height: _barHeight + _domeHitOverhang + bottomPad,
      width: screenWidth,
      // Translucent, deliberately: the drag recognizer needs to see pointers
      // anywhere over the bar, but this box also overhangs body content (the
      // Scaffold uses extendBody), and an opaque box would swallow taps meant
      // for it. Translucent puts this in the gesture arena *and* keeps
      // hit-testing what's behind — a still tap still goes to the body/icons,
      // only an actual horizontal drag is claimed here.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight + _domeHitOverhang,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                // Fractional selected index — the finger's position while the
                // wheel is being turned by hand, otherwise the old → new
                // settle animation.
                final selFloat = _dragFloat ?? _selFloatFor(widget.selectedIndex);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── The disk (dome), raised above the bar's top edge ──
                    Positioned(
                      top: boxTop,
                      left: 0,
                      right: 0,
                      height: boxHeight,
                      child: ClipRect(
                        child: CustomPaint(
                          size: Size(screenWidth, boxHeight),
                          painter: _DiskPainter(
                            centerX: centreX,
                            centerY: _diskR + 2, // local to this raised box
                            radius: _diskR,
                            selFloat: selFloat,
                            isDark: AppTheme.instance.isDark,
                          ),
                        ),
                      ),
                    ),
                    // ── The icons riding on the disk ─────────────────────
                    ..._buildIcons(n, centreX, diskCenterY, selFloat),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIcons(
    int n,
    double centreX,
    double diskCenterY,
    double selFloat,
  ) {
    // Collect every visible copy (including wrap-around neighbours).
    final items = <({int index, double angle})>[];
    for (var i = 0; i < n; i++) {
      final rel = i - selFloat;
      for (final cand in [rel, rel + n, rel - n]) {
        final angle = cand * _stepRad;
        if (angle.abs() < _windowRad) {
          items.add((index: i, angle: angle));
        }
      }
    }

    // Draw the outermost first so the centre icon ends up on top.
    items.sort((a, b) => b.angle.abs().compareTo(a.angle.abs()));

    return items.map((it) {
      final angle = it.angle;
      final absA = angle.abs();

      final opacity = ((_windowRad - absA) / (_windowRad - _fadeStart)).clamp(0.0, 1.0);
      if (opacity <= 0) return const SizedBox.shrink();

      // 1 at the very centre, 0 by the time it reaches the next slot.
      final fabFrac = (1 - absA / _stepRad).clamp(0.0, 1.0);

      final itemSize = ui.lerpDouble(_iconBoxSize, _fabSize, fabFrac)!;
      final iconSz = ui.lerpDouble(21.0, 26.0, fabFrac)!;
      final bgColor = Color.lerp(Colors.transparent, AppColors.primary, fabFrac)!;
      final iconColor = Color.lerp(AppColors.navUnsel, Colors.white, fabFrac)!;
      final iconBottomPad = ui.lerpDouble(12.0, 0.0, fabFrac)!;

      // Position on the ring; the icon tilts with the wheel (turntable feel).
      // The selected icon rides a *larger* radius so it climbs out of the
      // disk and floats on its rim — half in, half out — like a FAB resting
      // on top of the dome; as the wheel turns it sinks back onto the ring.
      final r = ui.lerpDouble(_pathR, _selectedR, fabFrac)!;
      final cx = centreX + r * math.sin(angle);
      final cy = diskCenterY - r * math.cos(angle);

      final shadows = fabFrac > 0.2
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5 * fabFrac),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ]
          : const <BoxShadow>[];

      // The tappable square is at least [_minTapTarget] on a side, even when
      // the visible icon (itemSize) is smaller — the unselected icons are only
      // 40px, below the ~44px minimum a finger reliably hits. The visual sits
      // centred and unrotated inside this box, so enlarging the hit area never
      // moves or turns the icon. Boxes stay well clear of overlapping (the
      // icon centres are ~70px apart), and where they do, the sort above draws
      // the more-central icon last, so it wins the touch.
      final hitSize = math.max(itemSize, _minTapTarget);

      return Positioned(
        left: cx - hitSize / 2,
        top: cy - hitSize / 2,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onTap(it.index),
            child: SizedBox(
              width: hitSize,
              height: hitSize,
              child: Center(
                child: Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      boxShadow: shadows,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: iconBottomPad),
                      child: Center(
                        child: HugeIcon(icon: _icons[it.index], color: iconColor, size: iconSz),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Draws the dome-shaped disk with a top rim highlight.
class _DiskPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double radius;
  final double selFloat;
  final bool isDark;

  const _DiskPainter({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.selFloat,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(centerX, centerY);

    if (!isDark) {
      // The white dome needs a cast shadow to read against a light body.
      canvas.drawShadow(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
        Colors.black.withValues(alpha: 0.18),
        10,
        false,
      );
    }

    // Dome fill — lighter at the top rim, darker lower down.
    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy - radius + 120),
        isDark ? [const Color(0xFF2C2C3E), const Color(0xFF191922)] : [const Color(0xFFFFFFFF), const Color(0xFFEDEDF3)],
      );
    canvas.drawCircle(center, radius, fill);

    // Rim highlight.
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(_DiskPainter old) => old.centerX != centerX || old.centerY != centerY || old.radius != radius || old.selFloat != selFloat || old.isDark != isDark;
}
