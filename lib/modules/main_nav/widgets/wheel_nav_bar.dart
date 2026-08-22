import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import 'wheel_nav_bar_disk_painter.dart';

part 'wheel_nav_bar_geometry.dart';
part 'wheel_nav_bar_gestures.dart';
part 'wheel_nav_bar_icons.dart';

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

class _WheelNavBarState extends State<WheelNavBar>
    with SingleTickerProviderStateMixin {
  // Every geometry/timing constant this class and its part files use lives
  // in wheel_nav_bar_geometry.dart — _icons, _barHeight, _diskR, _pathR,
  // _stepRad, _domeLift, _domeHitOverhang, _windowRad, _fadeStart,
  // _pxPerStep, _flingVelocity, etc.

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

  // setState is @protected — the gesture/icon-layout methods split into the
  // part files below live in extensions, not subclasses, so they call this
  // thin wrapper instead of setState directly.
  void _setState(VoidCallback fn) => setState(fn);

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
    final boxTop =
        _domeHitOverhang - (_domeLift + 2); // +2px so the apex isn't clipped
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
                final selFloat =
                    _dragFloat ?? _selFloatFor(widget.selectedIndex);

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
                          painter: DiskPainter(
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
}
