import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws the dome-shaped disk with a top rim highlight. Fully self-contained
/// — no shared state with [WheelNavBar], so it needs nothing from the part
/// files that split that class up.
class DiskPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double radius;
  final double selFloat;
  final bool isDark;

  const DiskPainter({
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
        isDark
            ? [const Color(0xFF2C2C3E), const Color(0xFF191922)]
            : [const Color(0xFFFFFFFF), const Color(0xFFEDEDF3)],
      );
    canvas.drawCircle(center, radius, fill);

    // Rim highlight.
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(DiskPainter old) =>
      old.centerX != centerX ||
      old.centerY != centerY ||
      old.radius != radius ||
      old.selFloat != selFloat ||
      old.isDark != isDark;
}
