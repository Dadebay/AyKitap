import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/app_prefs.dart';
import '../library/offline_library_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../main_nav/main_nav_screen.dart';
import '../../core/localization/strings/splash_strings.dart';

/// Branded splash: the logo springs in over a pulsing gradient halo, the
/// wordmark and tagline rise beneath it, and a slim loader runs while we
/// decide where to send the user (onboarding on first launch, otherwise
/// straight into the app).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Logo colours pulled from the app icon.
  static const _gradient = [Color(0xFFFFC876), Color(0xFFF77E68), Color(0xFFB44BE8)];

  // One-shot entrance timeline.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  // Endless subtle motion for the halo + loader.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
  );
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
  );
  late final Animation<double> _loader = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: AppTheme.instance.isDark ? Brightness.light : Brightness.dark,
    ));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Run the prefs read, the connectivity check, and a minimum splash
    // display time in parallel so the animation always gets to breathe,
    // even on a fast device.
    final results = await Future.wait([
      AppPrefs.isOnboardingSeen(),
      Connectivity().checkConnectivity(),
      Future.delayed(const Duration(milliseconds: 2600)),
    ]);
    if (!mounted) return;

    final seen = results[0] as bool;
    final connectivity = results[1] as List<ConnectivityResult>;
    // TZ 12.6: with no network at all, skip straight to the offline
    // library instead of the normal flow (onboarding needs a fresh install
    // to have never happened, and the catalogue itself needs a backend).
    final isOffline = connectivity.every((r) => r == ConnectivityResult.none);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isOffline
            ? const OfflineLibraryScreen()
            : (seen ? const MainNavScreen() : const OnboardingScreen()),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.1,
            colors: [
              isDark ? const Color(0xFF201436) : const Color(0xFFFFEADA),
              AppColors.bg,
            ],
            stops: [0.0, 0.75],
          ),
        ),
        child: Stack(
          children: [
            // Faint vignette at the bottom for depth.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDark ? const Color(0xFF0C0C12) : const Color(0xFFE7E2DE),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 3),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildWordmark(),
                  const SizedBox(height: 14),
                  _buildTagline(),
                  const Spacer(flex: 3),
                  _buildLoader(),
                  const SizedBox(height: 8),
                  _buildFooter(),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _ambient]),
      builder: (context, _) {
        final pulse = 0.5 + 0.5 * math.sin(_ambient.value * 2 * math.pi);
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing gradient halo behind the logo.
              Opacity(
                opacity: _logoFade.value * (0.35 + 0.25 * pulse),
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
                opacity: _logoFade.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB44BE8).withValues(alpha: 0.4 * _logoFade.value),
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

  Widget _buildWordmark() {
    return AnimatedBuilder(
      animation: _wordmark,
      builder: (context, child) {
        return Opacity(
          opacity: _wordmark.value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - _wordmark.value)), child: child),
        );
      },
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(colors: _gradient).createShader(rect),
        child: Text(
          SplashStrings.wordmark,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: _tagline,
      builder: (context, child) => Opacity(opacity: _tagline.value, child: child),
      child: Text(
        SplashStrings.tagline,
        style: TextStyle(color: AppColors.grey2, fontSize: 14, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildLoader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_loader, _ambient]),
      builder: (context, _) {
        return Opacity(
          opacity: _loader.value,
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
                    alignment: Alignment(-1 + 2 * _ambient.value, 0),
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

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _tagline,
      builder: (context, child) => Opacity(opacity: _tagline.value * 0.6, child: child),
      child: Text(SplashStrings.version, style: TextStyle(color: AppColors.grey3, fontSize: 11)),
    );
  }
}
