part of 'wheel_nav_bar.dart';

/// [_WheelNavBarState._buildIcons] — split out of wheel_nav_bar.dart to keep
/// that file under the 200-line limit. Pure mechanical move: every
/// expression here is unchanged from before the split — the geometry
/// constants it reads (`_stepRad`, `_windowRad`, `_pathR`, etc.) live in
/// wheel_nav_bar_geometry.dart, another `part` of the same library.
extension _WheelNavBarIcons on _WheelNavBarState {
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

      final opacity =
          ((_windowRad - absA) / (_windowRad - _fadeStart)).clamp(0.0, 1.0);
      if (opacity <= 0) return const SizedBox.shrink();

      // 1 at the very centre, 0 by the time it reaches the next slot.
      final fabFrac = (1 - absA / _stepRad).clamp(0.0, 1.0);

      final itemSize = ui.lerpDouble(_iconBoxSize, _fabSize, fabFrac)!;
      final iconSz = ui.lerpDouble(21.0, 26.0, fabFrac)!;
      final bgColor =
          Color.lerp(Colors.transparent, AppColors.primary, fabFrac)!;
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
                        child: _buildTabGlyph(
                            it.index, itemSize, iconColor, iconSz),
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

  /// The profile tab shows the signed-in user's actual avatar once one is
  /// set (leaving a ring of [itemSize]'s badge colour visible around it, the
  /// same highlight every other tab gets on selection); every other tab, and
  /// a profile with no avatar chosen yet, keeps the plain [HugeIcon].
  Widget _buildTabGlyph(
      int index, double itemSize, Color iconColor, double iconSz) {
    return HugeIcon(icon: _icons[index], color: iconColor, size: iconSz);
  }
}
