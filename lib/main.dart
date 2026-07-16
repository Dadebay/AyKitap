import 'dart:async';

import 'package:aykitap/global_safe_area_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/data/book_repository.dart';
import 'core/data/mock_book_repository.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/localization_delegates.dart';
import 'core/services/analytics_service.dart';
import 'core/services/bookmarks_store.dart';
import 'core/services/device_fingerprint.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notes_store.dart';
import 'core/services/own_books_store.dart';
import 'core/services/purchased_books_store.dart';
import 'core/services/streak_service.dart';
import 'core/services/subscription_service.dart';
import 'core/theme/theme_controller.dart';
import 'modules/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Hide Android's 3-button navigation bar entirely (keep the status bar).
  // A swipe up from the bottom edge still reveals it temporarily.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  await AppTheme.instance.load();
  // Must precede AppLocale.load(), which sets Intl.defaultLocale to a locale
  // whose date symbols this call is what makes available.
  await initializeDateFormatting();
  await AppLocale.instance.load();
  // Awaited so the navigator observer exists by the time MaterialApp builds;
  // it never throws, so a Firebase outage can't block startup.
  await AnalyticsService.instance.init();
  unawaited(AnalyticsService.instance.setLanguage(AppLocale.instance.current.name));
  // Firebase only came up on a supported platform (see AnalyticsService);
  // push notifications ride on the same Firebase app, so gate on that too.
  // Fire-and-forget: token/permission prompts shouldn't add latency to boot.
  if (AnalyticsService.instance.isEnabled) {
    unawaited(FirebaseMessagingService.instance.init());
  }
  // Fire-and-forget: resolve and cache the device fingerprint now so it's
  // ready by the time the user reaches login, with no added latency there.
  unawaited(DeviceFingerprint.get());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>.value(value: AppTheme.instance),
        ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
        ChangeNotifierProvider<StreakService>.value(value: StreakService.instance),
        ChangeNotifierProvider<SubscriptionService>.value(value: SubscriptionService.instance),
        ChangeNotifierProvider<NotesStore>.value(value: NotesStore.instance),
        ChangeNotifierProvider<BookmarksStore>.value(value: BookmarksStore.instance),
        ChangeNotifierProvider<PurchasedBooksStore>.value(value: PurchasedBooksStore.instance),
        ChangeNotifierProvider<OwnBooksStore>.value(value: OwnBooksStore.instance),
        Provider<BookRepository>(create: (_) => MockBookRepository()),
      ],
      child: const AykitapApp(),
    ),
  );
}

class AykitapApp extends StatelessWidget {
  const AykitapApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever the theme or language is toggled —
    // AppColors reads AppTheme.instance.isDark and every screen's strings
    // read AppLocale.instance.current directly, so this is what actually
    // reskins/retranslates every screen.
    final isDark = context.watch<AppTheme>().isDark;
    context.watch<AppLocale>();
    return MaterialApp(
      title: 'Aýkitap',
      debugShowCheckedModeBanner: false,
      locale: AppLocale.instance.locale,
      supportedLocales: kAppSupportedLocales,
      localizationsDelegates: kAppLocalizationsDelegates,
      navigatorObservers: AnalyticsService.instance.navigatorObservers,
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
  }
}
