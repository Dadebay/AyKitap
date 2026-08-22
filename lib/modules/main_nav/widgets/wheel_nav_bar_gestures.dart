part of 'wheel_nav_bar.dart';

/// [_WheelNavBarState]'s drag/settle math — split out of wheel_nav_bar.dart
/// to keep that file under the 200-line limit. Pure mechanical move: every
/// expression here is unchanged from before the split — the geometry/timing
/// constants it reads (`_pxPerStep`, `_flingVelocity`, `_icons`) live in
/// wheel_nav_bar_geometry.dart, another `part` of the same library.
extension _WheelNavBarGestures on _WheelNavBarState {
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
    _setState(() {
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
    _setState(() => _dragFloat = next);
  }

  void _onDragEnd(DragEndDetails details) {
    final drag = _dragFloat;
    if (drag == null) return;
    final n = _icons.length;
    final vx = details.velocity.pixelsPerSecond.dx;

    // Nearest slot normally; a flick instead carries the wheel on in the
    // direction it was thrown, so a short-but-fast swipe still changes tab
    // rather than snapping back.
    final slot = vx.abs() >= _flingVelocity
        ? (vx < 0 ? drag.ceil() : drag.floor())
        : drag.round();
    var target = slot % n;
    if (target < 0) target += n;

    _setState(() {
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
    _setState(() {
      _fromFloat = drag;
      _dragFloat = null;
      _lastDetent = null;
    });
    _ctrl.forward(from: 0);
  }
}
