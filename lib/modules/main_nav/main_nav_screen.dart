import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/localization/app_locale.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../reader/views/reader_tab_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _prevIndex = 0;
  // +1 → the new page slides in from the right (wheel spins forward);
  // -1 → in from the left. Kept in sync with the wheel's rotation direction.
  int _slideDir = 1;

  // Page widgets are cached (not rebuilt from a getter each frame): during
  // the slide the AnimatedBuilder ticks ~60fps, and re-creating heavy pages
  // like HomeScreen every tick would tank the framerate and make the
  // transition look like a freeze. Passing the *same* instances lets Flutter
  // skip rebuilding them, so only the cheap translation animates. Rebuilt on
  // theme/language change so AppColors and every screen's strings are re-read
  // — these tabs are never re-pushed via Navigator, so nothing else forces
  // them to notice AppLocale changing.
  late List<Widget> _pages = _buildPages();

  List<Widget> _buildPages() => [
        HomeScreen(),
        SearchScreen(),
        ReaderTabScreen(),
        LibraryScreen(),
        ProfileScreen(),
      ];

  // Slides the outgoing page out and the incoming one in, matching the
  // wheel nav's turntable spin.
  late final AnimationController _pageCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _pageAnim = CurvedAnimation(
    parent: _pageCtrl,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _pageCtrl.value = 1; // start settled (no transition on first frame)
    AppTheme.instance.addListener(_onRebuildNeeded);
    AppLocale.instance.addListener(_onRebuildNeeded);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    AppTheme.instance.removeListener(_onRebuildNeeded);
    AppLocale.instance.removeListener(_onRebuildNeeded);
    super.dispose();
  }

  void _onRebuildNeeded() => setState(() => _pages = _buildPages());

  // Shortest signed step around the ring of tabs — same logic the wheel uses
  // to decide which way to spin, so the page slide and the wheel agree.
  int _circularDir(int from, int to, int n) {
    var x = (to - from) % n;
    if (x < 0) x += n;
    return x <= n / 2 ? 1 : -1;
  }

  void _onTap(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _prevIndex = _selectedIndex;
      _slideDir = _circularDir(_selectedIndex, index, _pages.length);
      _selectedIndex = index;
    });
    _pageCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: _buildAnimatedBody(),
      bottomNavigationBar: _WheelNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return AnimatedBuilder(
      animation: _pageAnim,
      builder: (context, _) {
        final t = _pageAnim.value;
        // ONE stable structure for every state: all pages live permanently
        // in the same Positioned.fill slots (built once, kept alive like an
        // IndexedStack). Only each page's horizontal translation changes —
        // a paint-only transform — so no page is ever rebuilt or disposed
        // mid-navigation. That keeps heavy pages like HomeScreen from
        // re-building on each transition, which is what caused the stutter.
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: List.generate(_pages.length, (i) {
            double dx;
            if (i == _selectedIndex) {
              dx = _slideDir * (1 - t); // incoming: from the _slideDir side to 0
            } else if (i == _prevIndex && t < 1.0) {
              dx = -_slideDir * t; // outgoing: 0 → off the opposite side
            } else {
              dx = 2.0; // parked off-screen (clipped away, invisible)
            }
            return Positioned.fill(
              child: FractionalTranslation(
                translation: Offset(dx, 0),
                child: IgnorePointer(
                  ignoring: i != _selectedIndex,
                  child: _pages[i],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// A turntable-style nav bar: icons sit on a visible dome (the "disk").
/// Tapping an icon rotates the whole disk like a wheel so that icon rises
/// to the top-centre; the icon leaving the centre curves around to the side.
class _WheelNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _WheelNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_WheelNavBar> createState() => _WheelNavBarState();
}

class _WheelNavBarState extends State<_WheelNavBar> with SingleTickerProviderStateMixin {
  static const _icons = [
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedSearch01,
    HugeIcons.strokeRoundedPlay,
    HugeIcons.strokeRoundedLibrary,
    HugeIcons.strokeRoundedUser,
  ];

  // ── Geometry ────────────────────────────────────────────────────────────
  static const _barHeight = 82.0;
  static const _fabSize = 56.0;
  static const _iconBoxSize = 40.0;

  static const _diskR = 190.0; // radius of the dome — a true circle, not an ellipse
  static const _pathR = 152.0; // radius of the ring the icons travel on
  static const _stepRad = 34.0 * math.pi / 180.0; // angle between two icons
  static const _domeLift = 20.0; // how far the dome pokes above the bar's top edge

  // Only icons whose angle from the top is inside this window are drawn.
  // With 5 icons the farthest slot is still 2 steps away (2 * _stepRad ≈
  // 1.40rad, same as with 4), so both bounds must clear that to keep every
  // icon fully opaque at rest.
  static const _windowRad = 1.90;
  static const _fadeStart = 1.60;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutBack,
  );

  int _fromIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(_WheelNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _fromIndex = old.selectedIndex;
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
    // Icon math stays in this "outer" frame (unshifted, y=0 = bar's own
    // top). The dome itself is raised by _domeLift so its cap pokes above
    // the bar into the body content behind it.
    final diskCenterY = _diskR - _domeLift;
    final boxTop = -(_domeLift + 2); // +2px safety margin so the apex isn't clipped
    final boxHeight = _barHeight - boxTop;

    return SizedBox(
      height: _barHeight + bottomPad,
      width: screenWidth,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              // Fractional selected index — animates old → new.
              final delta = _circular(
                (widget.selectedIndex - _fromIndex).toDouble(),
                n,
              );
              final selFloat = _fromIndex + delta * _anim.value;

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
                  // ── The icons riding on the disk ───────────────────────
                  ..._buildIcons(n, centreX, diskCenterY, selFloat),
                ],
              );
            },
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
      final cx = centreX + _pathR * math.sin(angle);
      final cy = diskCenterY - _pathR * math.cos(angle);

      final shadows = fabFrac > 0.2
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5 * fabFrac),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ]
          : const <BoxShadow>[];

      return Positioned(
        left: cx - itemSize / 2,
        top: cy - itemSize / 2,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onTap(it.index),
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
