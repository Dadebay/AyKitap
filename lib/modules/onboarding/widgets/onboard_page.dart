import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OnboardPageData {
  final List<Color> gradient;
  final Color accentColor;
  final String image;
  final String title;
  final String subtitle;
  final String badge;
  final String badgeLabel;

  const OnboardPageData({
    required this.gradient,
    required this.accentColor,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeLabel,
  });
}

class OnboardPage extends StatelessWidget {
  final OnboardPageData data;
  final double textBottom;
  const OnboardPage({super.key, required this.data, required this.textBottom});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // ── Illustration ──────────────────────────────────────────
          // The photo itself fades to transparent (not clipped by a hard
          // box edge), so the container's own gradient shows through
          // underneath with no seam.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.72,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.55, 0.82, 1.0],
                colors: [Colors.white, Colors.white, Colors.white24, Colors.transparent],
              ).createShader(rect),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(data.image, fit: BoxFit.cover),
                  // Tint the photo with the page's own color so it reads as
                  // part of the same scene instead of a pasted-in cutout.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.gradient.first.withValues(alpha: 0.35),
                          data.accentColor.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                  // Soften the very top edge into the status bar.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.12],
                        colors: [data.gradient.first.withValues(alpha: 0.45), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badge (top-left, clear of the Skip button on the right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: data.accentColor.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.badge, style: TextStyle(color: data.accentColor, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Text(data.badgeLabel, style: TextStyle(color: AppColors.grey1, fontSize: 12)),
                ],
              ),
            ),
          ),

          // ── Text ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: textBottom,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: AppColors.grey2, fontSize: 15.5, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
