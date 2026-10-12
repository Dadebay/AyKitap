import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// One tab's icon on the [WheelNavBar], plus the little scene it plays each
/// time its tab becomes selected.
///
/// Every tab tells a tiny story about what it is, instead of all of them doing
/// the same generic pop:
///
/// - Profile  — the head glances left, then right, then back to centre
/// - Library  — the upright book hops, the leaning one rocks like it was just
///              pulled off the shelf
/// - Home     — the house hops, blinks, and floats two hearts up
/// - Çytalka  — sound waves ripple out of the play triangle
/// - Search   — the magnifier sweeps a circle, a glint crosses the lens and a
///              sparkle pops out: "found it"
///
/// At rest (and whenever no scene is running) this is a plain [HugeIcon], so
/// the unselected icons cost nothing. Scenes are drawn on the same 24×24 grid
/// as the HugeIcons glyphs and in the same stroke weight, so the glyph never
/// visibly changes style when a scene starts or ends.
class WheelNavGlyph extends StatefulWidget {
  const WheelNavGlyph({
    super.key,
    required this.index,
    required this.icon,
    required this.size,
    required this.color,
    required this.selected,
    required this.animate,
  });

  /// Tab slot — must stay in lockstep with `_icons` in wheel_nav_bar_geometry.
  final int index;
  final List<List<dynamic>> icon;
  final double size;
  final Color color;

  /// True only for the one on-screen copy of the selected tab.
  final bool selected;

  /// False when the OS asks for reduced motion.
  final bool animate;

  @override
  State<WheelNavGlyph> createState() => _WheelNavGlyphState();
}

class _WheelNavGlyphState extends State<WheelNavGlyph>
    with SingleTickerProviderStateMixin {
  // The first stretch is a rest while the wheel is still carrying the icon up
  // to the centre; [_progress] skips it.
  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void didUpdateWidget(WheelNavGlyph old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && widget.animate) {
      _scene.forward(from: 0);
    } else if (!widget.selected && old.selected) {
      _scene.reset();
    }
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  double get _progress => ((_scene.value - 0.12) / 0.88).clamp(0.0, 1.0);

  Widget _rest() =>
      HugeIcon(icon: widget.icon, color: widget.color, size: widget.size);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scene,
      builder: (context, _) {
        if (!_scene.isAnimating) return _rest();
        final s = _progress;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: switch (widget.index) {
            0 => _profile(s),
            1 => _library(s),
            2 => _home(s),
            3 => _play(s),
            _ => _search(s),
          },
        );
      },
    );
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Widget _profile(double s) {
    // One continuous swing: left, through the centre, right, and settling with
    // zero speed at both ends so it never stops dead on a pose.
    // 0.7698 is the peak of sin(2πu)·sin(πu), normalising it to ±1.
    final look = -math.sin(2 * math.pi * s) * math.sin(math.pi * s) / 0.7698;
    return CustomPaint(painter: _UserPainter(look, widget.color));
  }

  // ── Library ──────────────────────────────────────────────────────────────

  Widget _library(double s) {
    final k = widget.size / 24;
    final hopT = (s / 0.38).clamp(0.0, 1.0);
    final hop = math.sin(math.pi * hopT);
    final rockT = ((s - 0.18) / 0.82).clamp(0.0, 1.0);
    // Leans out further, then rocks back to rest.
    final rock = 0.42 * math.sin(2.2 * math.pi * rockT) * (1 - rockT);
    // The glyph's two books sit either side of x ≈ 10.8 with a clear gap; the
    // cut is placed just past the upright book's stroke so no sliver of it
    // stays behind in the leaning book's half.
    const split = 10.8 / 24;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(0, -2.8 * k * hop),
          child: ClipRect(
            clipper: const _ColumnBand(-2, split),
            child: _rest(),
          ),
        ),
        Transform.rotate(
          angle: rock,
          alignment: const Alignment(0.25, 0.75),
          child: ClipRect(
            clipper: const _ColumnBand(split, 3),
            child: _rest(),
          ),
        ),
      ],
    );
  }

  // ── Home ─────────────────────────────────────────────────────────────────

  Widget _home(double s) {
    final k = widget.size / 24;
    final hopT = (s / 0.58).clamp(0.0, 1.0);
    final bounce = math.sin(hopT * 2.2 * math.pi).abs() * (1 - hopT);
    final house = Transform(
      alignment: const Alignment(0, 0.9),
      transform: Matrix4.identity()
        ..translateByDouble(0, -3.2 * k * bounce, 0, 1)
        ..scaleByDouble(1 - 0.06 * bounce, 1 + 0.09 * bounce, 1, 1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _rest(),
          CustomPaint(
            size: Size.square(widget.size),
            painter: _EyesPainter(s, widget.color),
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        house,
        CustomPaint(
          size: Size.square(widget.size),
          painter: _HeartsPainter(s, widget.color),
        ),
      ],
    );
  }

  // ── Çytalka ──────────────────────────────────────────────────────────────

  Widget _play(double s) {
    final k = widget.size / 24;
    final nudge = math.sin(math.pi * (s / 0.45).clamp(0.0, 1.0));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(offset: Offset(-1.4 * k * nudge, 0), child: _rest()),
        CustomPaint(
          size: Size.square(widget.size),
          painter: _WavesPainter(s, widget.color),
        ),
      ],
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────

  Widget _search(double s) {
    final k = widget.size / 24;
    // Orbit radius grows then shrinks, so it starts and ends exactly at rest.
    final r = 2.2 * k * math.sin(math.pi * s);
    final a = s * 3 * math.pi;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(r * (math.cos(a) - 1), r * math.sin(a)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _rest(),
              CustomPaint(
                size: Size.square(widget.size),
                painter: _GlintPainter(s, widget.color),
              ),
            ],
          ),
        ),
        CustomPaint(
          size: Size.square(widget.size),
          painter: _SparklePainter(s, widget.color),
        ),
      ],
    );
  }
}

/// Clips to a vertical column given as fractions of the child's width, with the
/// height left unbounded so a hopping or rocking book is never cut off.
class _ColumnBand extends CustomClipper<Rect> {
  const _ColumnBand(this.left, this.right);

  final double left;
  final double right;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        size.width * left,
        -size.height,
        size.width * right,
        size.height * 2,
      );

  @override
  bool shouldReclip(_ColumnBand old) => old.left != left || old.right != right;
}

Paint _stroke(Color color, {double width = 1.5}) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// The HugeIcons user glyph, redrawn in two pieces so the head can turn on the
/// neck: it narrows and shifts toward the side it looks at while the shoulders
/// follow a hair the other way.
class _UserPainter extends CustomPainter {
  const _UserPainter(this.look, this.color);

  final double look; // -1 left … 1 right
  final Color color;

  static final Path _shoulders = Path()
    ..moveTo(19, 20.5)
    ..cubicTo(19, 16.634, 15.866, 13.5, 12, 13.5)
    ..cubicTo(8.13401, 13.5, 5, 16.634, 5, 20.5);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = _stroke(color);

    canvas.save();
    canvas.translate(-look * 0.5, 0);
    canvas.drawPath(_shoulders, paint);
    canvas.restore();

    canvas.save();
    canvas.translate(12 + look * 1.7, 8.5 + look.abs() * 0.4);
    canvas.rotate(look * 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: 10 * (1 - 0.22 * look.abs()),
        height: 10,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UserPainter old) =>
      old.look != look || old.color != color;
}

/// Two eyes that pop onto the house, blink once and fade — the smile curve
/// already in the glyph becomes a face.
class _EyesPainter extends CustomPainter {
  const _EyesPainter(this.s, this.color);

  final double s;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final pop = Curves.easeOutBack.transform(((s - 0.06) / 0.14).clamp(0.0, 1.0));
    final fade = 1 - ((s - 0.78) / 0.12).clamp(0.0, 1.0);
    final blink =
        1 - 0.9 * math.sin(math.pi * ((s - 0.46) / 0.12).clamp(0.0, 1.0));
    final e = pop * fade;
    if (e <= 0.01) return;
    final paint = Paint()..color = color;
    for (final cx in const [9.2, 14.8]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, 13.6),
          width: 1.7 * e,
          height: 2.1 * e * blink,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EyesPainter old) => old.s != s || old.color != color;
}

/// Hearts that pop in over the roof, drift up and fade.
class _HeartsPainter extends CustomPainter {
  const _HeartsPainter(this.s, this.color);

  final double s;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    _heart(canvas, const Offset(8.6, 5.2), 1.9, (s - 0.22) / 0.5);
    _heart(canvas, const Offset(14.4, 4.6), 1.5, (s - 0.40) / 0.5);
  }

  void _heart(Canvas canvas, Offset origin, double size, double t) {
    if (t <= 0 || t >= 1) return;
    final rise = Curves.easeOut.transform(t) * 5.2;
    final pop = Curves.easeOutBack.transform((t * 4).clamp(0.0, 1.0));
    final alpha = math.sin(math.pi * t).clamp(0.0, 1.0);
    final c = origin - Offset(0, rise);
    final h = size * pop;
    final path = Path()
      ..moveTo(c.dx, c.dy + h * 0.9)
      ..cubicTo(c.dx - h * 1.3, c.dy + h * 0.1, c.dx - h * 1.0, c.dy - h * 0.9,
          c.dx, c.dy - h * 0.35)
      ..cubicTo(c.dx + h * 1.0, c.dy - h * 0.9, c.dx + h * 1.3, c.dy + h * 0.1,
          c.dx, c.dy + h * 0.9)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(_HeartsPainter old) => old.s != s || old.color != color;
}

/// Three sound waves rippling out to the right of the play triangle.
class _WavesPainter extends CustomPainter {
  const _WavesPainter(this.s, this.color);

  final double s;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    const centre = Offset(12, 12);
    for (final start in const [0.10, 0.28, 0.46]) {
      final t = (s - start) / 0.46;
      if (t <= 0 || t >= 1) continue;
      final radius = 9.2 + 4.6 * Curves.easeOutCubic.transform(t);
      final alpha = (math.sin(math.pi * t) * 0.95).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -0.78,
        1.56,
        false,
        _stroke(color.withValues(alpha: alpha), width: 1.4),
      );
    }
  }

  @override
  bool shouldRepaint(_WavesPainter old) => old.s != s || old.color != color;
}

/// A soft diagonal shine that sweeps once across the magnifier's lens.
class _GlintPainter extends CustomPainter {
  const _GlintPainter(this.s, this.color);

  final double s;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final g = ((s - 0.12) / 0.5).clamp(0.0, 1.0);
    if (g <= 0 || g >= 1) return;
    canvas.scale(size.width / 24);
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 7.4)),
    );
    final travel = -12 + 24 * Curves.easeInOutCubic.transform(g);
    canvas.translate(11, 11);
    canvas.rotate(-math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(travel, 0), width: 2.8, height: 30),
      Paint()..color = color.withValues(alpha: 0.55 * math.sin(math.pi * g)),
    );
  }

  @override
  bool shouldRepaint(_GlintPainter old) => old.s != s || old.color != color;
}

/// A four-point sparkle that pops out beside the lens once the glint has
/// crossed it.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.s, this.color);

  final double s;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ((s - 0.5) / 0.45).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    canvas.scale(size.width / 24);
    final pop = Curves.easeOutBack.transform((t * 3).clamp(0.0, 1.0));
    final r = 3.0 * pop;
    canvas.translate(19.2, 3.8);
    canvas.rotate(t * 0.9);
    final star = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..quadraticBezierTo(0, 0, -r, 0)
      ..quadraticBezierTo(0, 0, 0, -r)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = color.withValues(alpha: math.sin(math.pi * t)),
    );
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.s != s || old.color != color;
}
