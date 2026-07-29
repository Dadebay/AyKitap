import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/splash_strings.dart';

const kSplashGradient = [Color(0xFFFFC876), Color(0xFFF77E68), Color(0xFFB44BE8)];

/// The pulsing gradient halo behind the app icon, springing in on
/// [entrance] while [ambient] drives its endless breathing pulse.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, required this.entrance, required this.ambient, required this.logoScale, required this.logoFade});

  final Animation<double> entrance;
  final Animation<double> ambient;
  final Animation<double> logoScale;
  final Animation<double> logoFade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([entrance, ambient]),
      builder: (context, _) {
        final pulse = 0.5 + 0.5 * math.sin(ambient.value * 2 * math.pi);
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing gradient halo behind the logo.
              Opacity(
                opacity: logoFade.value * (0.35 + 0.25 * pulse),
                child: Container(
                  width: 180 + 24 * pulse,
                  height: 180 + 24 * pulse,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFF77E68), Color(0xFFB44BE8), Colors.transparent],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // The logo itself.
              Opacity(
                opacity: logoFade.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: logoScale.value,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB44BE8).withValues(alpha: 0.4 * logoFade.value),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - animation.value)), child: child),
        );
      },
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(colors: kSplashGradient).createShader(rect),
        child: Text(
          SplashStrings.wordmark,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Congenial',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class SplashTagline extends StatelessWidget {
  const SplashTagline({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(opacity: animation.value, child: child),
      child: Text(
        SplashStrings.tagline,
        style: TextStyle(color: AppColors.grey2, fontSize: 14, letterSpacing: 0.3),
      ),
    );
  }
}

class SplashLoader extends StatelessWidget {
  const SplashLoader({super.key, required this.loader, required this.ambient});
  final Animation<double> loader;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([loader, ambient]),
      builder: (context, _) {
        return Opacity(
          opacity: loader.value,
          child: SizedBox(
            width: 120,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(color: AppColors.card),
                  // A gradient shard sweeping left→right.
                  Align(
                    alignment: Alignment(-1 + 2 * ambient.value, 0),
                    child: Container(
                      width: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFF77E68), Color(0xFFB44BE8), Colors.transparent]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplashFooter extends StatelessWidget {
  const SplashFooter({super.key, required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(opacity: animation.value * 0.6, child: child),
      child: Text(SplashStrings.version, style: TextStyle(color: AppColors.grey3, fontSize: 11)),
    );
  }
}
