import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/device_tier.dart';

/// New Year theme switch — on until 13 Jan 2027 (inclusive), then every
/// festive element (snow, sleigh, splash logo) disappears on its own.
bool get kNewYearTheme => DateTime.now().isBefore(DateTime(2027, 1, 14));

/// Number of screens that asked for the snow to rest (readers: falling flakes
/// over a page of text are a distraction). >0 hides the snow.
final ValueNotifier<int> snowfallPauseCount = ValueNotifier<int>(0);

/// Put anywhere in a screen's tree to hide the app-wide snow while it's open.
class SnowfallPause extends StatefulWidget {
  const SnowfallPause({super.key});

  @override
  State<SnowfallPause> createState() => _SnowfallPauseState();
}

class _SnowfallPauseState extends State<SnowfallPause> {
  @override
  void initState() {
    super.initState();
    // Deferred: listeners rebuild during the frame this widget is built in.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => snowfallPauseCount.value++);
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => snowfallPauseCount.value--);
    super.dispose();
  }

  // Sits directly in the readers' Stacks, so it must be a Positioned child: a
  // plain zero-size child would collapse the whole Stack to 0x0.
  @override
  Widget build(BuildContext context) => const Positioned(
      left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
}

/// App-wide gentle snowfall, drawn above every screen. Never takes touches.
class SnowfallOverlay extends StatelessWidget {
  const SnowfallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kNewYearTheme ||
        DeviceTier.isLowEnd ||
        MediaQuery.disableAnimationsOf(context)) {
      // Must stay a Positioned child: a plain zero-size child would collapse
      // the Stack it sits in (see ReaderScrollHint).
      return const Positioned(
          left: 0, top: 0, width: 0, height: 0, child: SizedBox.shrink());
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<int>(
          valueListenable: snowfallPauseCount,
          builder: (_, paused, __) =>
              paused > 0 ? const SizedBox.shrink() : const SnowfallLayer(),
        ),
      ),
    );
  }
}

/// The falling flakes themselves — a single painter driven by one ticker.
class SnowfallLayer extends StatefulWidget {
  const SnowfallLayer({super.key, this.count = 46});
  final int count;

  @override
  State<SnowfallLayer> createState() => _SnowfallLayerState();
}

/// 0 = plain round dot, 1 = six-arm twig flake, 2 = plain six-arm star,
/// 3 = flake with arrow-head tips.
class _Flake {
  _Flake(math.Random r) : this._(r, r.nextInt(10) < 4 ? 0 : 1 + r.nextInt(3));

  _Flake._(math.Random r, this.kind)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        radius = kind == 0
            ? 1.3 + r.nextDouble() * 1.7 // dots: 1.3–3 px
            : 3.2 + r.nextDouble() * 3.6, // flakes: 3.2–6.8 px
        spin = (r.nextDouble() - 0.5) * 1.2,
        angle0 = r.nextDouble() * math.pi,
        speed = 0.045 + r.nextDouble() * 0.07, // screens per second
        sway = 6 + r.nextDouble() * 16,
        phase = r.nextDouble() * math.pi * 2,
        opacity = 0.4 + r.nextDouble() * 0.5;
  double x, y; // 0..1 of the screen
  final int kind;
  final double radius, speed, sway, phase, opacity, spin, angle0;
}

class _SnowfallLayerState extends State<SnowfallLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final List<_Flake> _flakes;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _flakes = List.generate(widget.count, (_) => _Flake(r));
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      for (final f in _flakes) {
        f.y += f.speed * dt;
        if (f.y > 1.05) {
          f.y = -0.05;
          f.x = math.Random().nextDouble();
        }
      }
      _time.value = elapsed.inMicroseconds / 1e6;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SnowPainter(_flakes, _time),
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.flakes, this.time) : super(repaint: time);
  final List<_Flake> flakes;
  final ValueNotifier<double> time;

  /// Unit-radius shapes, built once and scaled/rotated per flake.
  /// Index = [_Flake.kind] (0 is drawn as a filled circle instead).
  static final List<Path> _shapes = [
    Path(),
    _build(twigs: true),
    _build(twigs: false),
    _build(twigs: false, tips: true),
  ];

  static Path _build({required bool twigs, bool tips = false}) {
    final path = Path();
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      path.moveTo(0, 0);
      path.lineTo(dir.dx, dir.dy);
      void branch(double at, double len, double spread) {
        final base = dir * at;
        for (final side in const [-1.0, 1.0]) {
          final b = a + side * spread;
          path.moveTo(base.dx, base.dy);
          path.lineTo(base.dx + len * math.cos(b), base.dy + len * math.sin(b));
        }
      }

      if (twigs) branch(0.58, 0.34, math.pi / 4);
      if (tips) branch(0.82, 0.28, math.pi / 3);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final t = time.value;
    for (final f in flakes) {
      final dx = math.sin(t * 0.8 + f.phase) * f.sway;
      final pos = Offset(f.x * size.width + dx, f.y * size.height);
      final color = Colors.white.withValues(alpha: f.opacity);
      if (f.kind == 0) {
        canvas.drawCircle(pos, f.radius, fill..color = color);
        continue;
      }
      stroke
        ..color = color
        // Stroke is applied after scaling, so divide it back out.
        ..strokeWidth = 0.95 / f.radius;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(f.angle0 + t * f.spin);
      canvas.scale(f.radius);
      canvas.drawPath(_shapes[f.kind], stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SnowPainter old) => false; // driven by `repaint`
}
