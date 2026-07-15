import 'dart:async';

import 'package:aykitap/global_safe_area_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/localization/app_locale.dart';
import 'core/services/device_fingerprint.dart';
import 'core/theme/theme_controller.dart';
import 'modules/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Hide Android's 3-button navigation bar entirely (keep the status bar).
  // A swipe up from the bottom edge still reveals it temporarily.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  await AppTheme.instance.load();
  await AppLocale.instance.load();
  // Fire-and-forget: resolve and cache the device fingerprint now so it's
  // ready by the time the user reaches login, with no added latency there.
  unawaited(DeviceFingerprint.get());
  runApp(const AykitapApp());
}

class AykitapApp extends StatelessWidget {
  const AykitapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever the theme or language is toggled —
    // AppColors reads AppTheme.instance.isDark and every screen's strings
    // read AppLocale.instance.current directly, so this is what actually
    // reskins/retranslates every screen.
    return ListenableBuilder(
      listenable: Listenable.merge([AppTheme.instance, AppLocale.instance]),
      builder: (context, _) {
        final isDark = AppTheme.instance.isDark;
        return MaterialApp(
          title: 'Aýkitap',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8712C), brightness: isDark ? Brightness.dark : Brightness.light),
            useMaterial3: true,
            fontFamily: 'Gilroy',
            appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true, scrolledUnderElevation: 0),
          ),
          builder: (context, child) {
            return GlobalSafeAreaWrapper(child: child ?? const SizedBox.shrink());
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
