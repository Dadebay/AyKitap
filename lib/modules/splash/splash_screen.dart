import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/navigation/fade_page_route.dart';
import '../../core/services/app_prefs.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/downloaded_files_store.dart';
import '../../core/services/home_data_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/theme_controller.dart';
import '../library/offline_library_screen.dart';
import '../main_nav/main_nav_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'widgets/splash_visuals.dart';

/// Branded splash: the logo springs in over a pulsing gradient halo, the
/// wordmark and tagline rise beneath it, and a slim loader runs while we
/// decide where to send the user (onboarding on first launch, otherwise
/// straight into the app).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// The floor on total splash time for a returning user — enough for the
  /// brand to register as an intentional moment rather than a flash, short
  /// enough not to read as a wait. Real work (prefs read, connectivity
  /// check, the entrance animation itself) runs in parallel with this, so
  /// this is a floor, not something added on top of them.
  @visibleForTesting
  static const minSplashDelay = Duration(milliseconds: 750);

  /// [minSplashDelay] under normal motion; zero under reduced motion, so
  /// nothing artificially stretches the wait beyond whatever the real prefs
  /// read and connectivity check already take on their own.
  @visibleForTesting
  static Duration splashFloorFor({required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : minSplashDelay;

  /// Pure routing decision, pulled out of [_SplashScreenState._bootstrap] so
  /// it's unit-testable without standing up [AppPrefs]/`Connectivity` (both
  /// platform-backed) or the animation lifecycle around it.
  @visibleForTesting
  static Widget destinationFor(
          {required bool isOffline, required bool onboardingSeen}) =>
      isOffline
          ? const OfflineLibraryScreen()
          : (onboardingSeen ? const MainNavScreen() : const OnboardingScreen());

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // One-shot entrance timeline. Duration set in [initState] — shortened (or
  // skipped outright) under reduced motion, so it can't be `late final` with
  // an inline initializer the way [_ambient] used to be.
  late final AnimationController _entrance;

  // Endless subtle motion for the halo + loader — never started at all under
  // reduced motion (see [initState]), so this stays put at its rest frame
  // instead of visibly animating.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

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

  // Guards the one-shot setup below — [didChangeDependencies] can fire more
  // than once (any ancestor InheritedWidget changing, not just MediaQuery),
  // but the entrance animation and _bootstrap must only ever start once.
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          AppTheme.instance.isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;
    // Moved here from initState: MediaQuery (via AppMotion.reduceMotion)
    // is an InheritedWidget lookup, and this screen sits under SafeArea /
    // MediaQuery ancestors that are themselves still partway through their
    // own first build the moment initState runs — Flutter's own dependency
    // machinery isn't ready for a descendant to read it that early and
    // throws "dependOnInheritedWidgetOfExactType() ... called before
    // initState() completed". didChangeDependencies is the framework's own
    // documented place for exactly this: it's guaranteed to run after
    // initState and before the first build, once dependencies are actually
    // resolved.
    final reduceMotion = AppMotion.reduceMotion(context);
    // `duration` only matters for the `forward()` branch below — never read
    // when reduced motion jumps straight to `value = 1`.
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    if (reduceMotion) {
      // Same convention [StaggerFadeIn] uses: jump straight to the settled
      // frame instead of animating through it.
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _ambient.repeat();
    }
    _bootstrap(reduceMotion);
  }

  Future<void> _bootstrap(bool reduceMotion) async {
    // Kicked off, not awaited: Home's `/collections/all` + `/banners` fetch
    // starts right now, during the splash animation, so it's already done
    // (or close to it) by the time the user actually reaches Home instead
    // of only starting once that screen mounts. HomeScreen/BannerCarousel
    // just watch HomeDataService rather than fetching on their own.
    unawaited(HomeDataService.instance.load());

    // The reading gate has to be able to answer offline, so its cached
    // state (purchased ids, subscription expiry, downloaded files) is read
    // from disk at boot rather than on the first book tapped. The purchased
    // list is then re-synced from the backend when there's a session —
    // best-effort, so this never delays the splash.
    unawaited(BookAccessService.instance
        .load()
        .then((_) => BookAccessService.instance.refreshPurchased()));
    unawaited(SubscriptionService.instance.load());
    unawaited(DownloadedFilesStore.instance.load());

    // Run the prefs read, the connectivity check, and a minimum splash
    // display time in parallel — real work never waits behind the floor,
    // and the floor never adds on top of real work that's already slower
    // than it. Reduced motion drops the floor to zero: the two real reads
    // are still awaited (this decides where to navigate), but nothing
    // artificially stretches the wait beyond what they actually take.
    final results = await Future.wait([
      AppPrefs.isOnboardingSeen(),
      Connectivity().checkConnectivity(),
      Future.delayed(SplashScreen.splashFloorFor(reduceMotion: reduceMotion)),
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
      FadePageRoute(
        reduceMotion: reduceMotion,
        child: SplashScreen.destinationFor(
            isOffline: isOffline, onboardingSeen: seen),
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
                      isDark
                          ? const Color(0xFF0C0C12)
                          : const Color(0x1AD8CFC4),
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
                  SplashLogo(
                      entrance: _entrance,
                      ambient: _ambient,
                      logoScale: _logoScale,
                      logoFade: _logoFade),
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
