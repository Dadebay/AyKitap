import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/app_prefs.dart';
import '../library/offline_library_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../main_nav/main_nav_screen.dart';
import 'widgets/splash_visuals.dart';

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
            // Faint vignette at the bottom for depth. In dark mode it deepens
            // toward near-black; in light mode it stays a barely-there tint so
            // it reads as gentle depth rather than a grey shadow band.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      isDark ? const Color(0xFF0C0C12) : const Color(0x1AD8CFC4),
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
                  SplashLogo(entrance: _entrance, ambient: _ambient, logoScale: _logoScale, logoFade: _logoFade),
                  const SizedBox(height: 28),
                  SplashWordmark(animation: _wordmark),
                  const SizedBox(height: 14),
                  SplashTagline(animation: _tagline),
                  const Spacer(flex: 3),
                  SplashLoader(loader: _loader, ambient: _ambient),
                  const SizedBox(height: 8),
                  SplashFooter(animation: _tagline),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
