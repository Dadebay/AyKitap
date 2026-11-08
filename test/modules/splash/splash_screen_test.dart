import 'package:aykitap/modules/library/offline_library_screen.dart';
import 'package:aykitap/modules/main_nav/main_nav_screen.dart';
import 'package:aykitap/modules/onboarding/onboarding_screen.dart';
import 'package:aykitap/modules/splash/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplashScreen.minSplashDelay', () {
    test('keeps the connection-check screen visible for two seconds', () {
      expect(SplashScreen.minSplashDelay, const Duration(seconds: 2));
    });

    test('splashFloorFor drops to zero under reduced motion', () {
      expect(SplashScreen.splashFloorFor(reduceMotion: false),
          SplashScreen.minSplashDelay);
      expect(SplashScreen.splashFloorFor(reduceMotion: true), Duration.zero);
    });
  });

  group('SplashScreen.destinationFor', () {
    test('offline always wins, regardless of onboarding state', () {
      expect(SplashScreen.destinationFor(isOffline: true, onboardingSeen: true),
          isA<OfflineLibraryScreen>());
      expect(
          SplashScreen.destinationFor(isOffline: true, onboardingSeen: false),
          isA<OfflineLibraryScreen>());
    });

    test('online and onboarding not seen goes to OnboardingScreen', () {
      expect(
          SplashScreen.destinationFor(isOffline: false, onboardingSeen: false),
          isA<OnboardingScreen>());
    });

    test('online and onboarding already seen goes to MainNavScreen', () {
      expect(
          SplashScreen.destinationFor(isOffline: false, onboardingSeen: true),
          isA<MainNavScreen>());
    });
  });
}
