import 'dart:async';

import 'package:aykitap/global_safe_area_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/localization_delegates.dart';
import 'core/navigation/root_navigator.dart';
import 'core/network/api_config.dart';
import 'core/services/account_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_activity_service.dart';
import 'core/services/book_access_service.dart';
import 'core/services/book_download_service.dart';
import 'core/services/bookmarks_store.dart';
import 'core/services/device_fingerprint.dart';
import 'core/services/downloaded_books_store.dart';
import 'core/services/downloaded_files_store.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/home_data_service.dart';
import 'core/services/home_screen_widget_service.dart';
import 'core/services/last_read_book_store.dart';
import 'core/services/notes_store.dart';
import 'core/services/own_books_store.dart';
import 'core/services/purchased_books_store.dart';
import 'core/services/reading_books_store.dart';
import 'core/services/streak_service.dart';
import 'core/services/subscription_service.dart';
import 'core/theme/theme_controller.dart';
import 'modules/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Default is 1000 images / 100MB — too tight for how many book covers Home,
  // Library and Search keep on screen at once, so returning from a detail
  // page after viewing a few others could evict an earlier cover and force
  // a visible reload. A bigger budget keeps decoded covers resident.
  PaintingBinding.instance.imageCache.maximumSize = 3000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Hide Android's 3-button navigation bar entirely (keep the status bar).
  // A swipe up from the bottom edge still reveals it temporarily.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top]);
  await AppTheme.instance.load();
  // Must precede AppLocale.load(), which sets Intl.defaultLocale to a locale
  // whose date symbols this call is what makes available.
  await initializeDateFormatting();
  await AppLocale.instance.load();
  // Awaited so the navigator observer exists by the time MaterialApp builds;
  // it never throws, so a Firebase outage can't block startup.
  await AnalyticsService.instance.init();
  unawaited(
      AnalyticsService.instance.setLanguage(AppLocale.instance.current.name));
  // Firebase only came up on a supported platform (see AnalyticsService);
  // push notifications ride on the same Firebase app, so gate on that too.
  // Fire-and-forget: token/permission prompts shouldn't add latency to boot.
  if (AnalyticsService.instance.isEnabled) {
    unawaited(FirebaseMessagingService.instance.init());
  }
  // Keep native home-screen widgets useful from their first render, even
  // before the user opens the Reader tab in this app session.
  await LastReadBookStore.instance.load();
  await StreakService.instance.load();
  final lastRead = LastReadBookStore.instance.book;
  unawaited(HomeScreenWidgetService.sync(
    bookId: lastRead?.bookId,
    title: lastRead?.title,
    page: lastRead?.page ?? 0,
    pageCount: lastRead?.pageCount,
    streak: StreakService.instance.currentStreak,
    bestStreak: StreakService.instance.bestStreak,
    todayPages: StreakService.instance.todayPages,
    goalMinutes: StreakService.instance.goalMinMinutes,
    weekRead: StreakService.instance.weekRead,
    coverUrl: lastRead?.image == null
        ? null
        : ApiConfig.resolveImageUrl(lastRead!.image!),
  ));
  // Fire-and-forget: resolve and cache the device fingerprint now so it's
  // ready by the time the user reaches login, with no added latency there.
  unawaited(DeviceFingerprint.get());
  // Foreground-time tracking for the admin dashboard's "most active users".
  // Started here rather than from a screen because it has to span the whole
  // process, not one route — it costs a single 60s timer and one int.
  AppActivityService.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppTheme>.value(value: AppTheme.instance),
        ChangeNotifierProvider<AppLocale>.value(value: AppLocale.instance),
        ChangeNotifierProvider<StreakService>.value(
            value: StreakService.instance),
        ChangeNotifierProvider<SubscriptionService>.value(
            value: SubscriptionService.instance),
        ChangeNotifierProvider<AccountService>.value(
            value: AccountService.instance),
        ChangeNotifierProvider<NotesStore>.value(value: NotesStore.instance),
        ChangeNotifierProvider<BookmarksStore>.value(
            value: BookmarksStore.instance),
        ChangeNotifierProvider<PurchasedBooksStore>.value(
            value: PurchasedBooksStore.instance),
        ChangeNotifierProvider<ReadingBooksStore>.value(
            value: ReadingBooksStore.instance),
        ChangeNotifierProvider<OwnBooksStore>.value(
            value: OwnBooksStore.instance),
        ChangeNotifierProvider<DownloadedBooksStore>.value(
            value: DownloadedBooksStore.instance),
        ChangeNotifierProvider<DownloadedFilesStore>.value(
            value: DownloadedFilesStore.instance),
        ChangeNotifierProvider<BookAccessService>.value(
            value: BookAccessService.instance),
        ChangeNotifierProvider<BookDownloadService>.value(
            value: BookDownloadService.instance),
        ChangeNotifierProvider<HomeDataService>.value(
            value: HomeDataService.instance),
        ChangeNotifierProvider<LastReadBookStore>.value(
            value: LastReadBookStore.instance),
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
      navigatorKey: rootNavigatorKey,
      title: 'Aýkitap',
      debugShowCheckedModeBanner: false,
      locale: AppLocale.instance.locale,
      supportedLocales: kAppSupportedLocales,
      localizationsDelegates: kAppLocalizationsDelegates,
      navigatorObservers: AnalyticsService.instance.navigatorObservers,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE8712C),
            brightness: isDark ? Brightness.dark : Brightness.light),
        useMaterial3: true,
        fontFamily: 'Gilroy',
        appBarTheme: const AppBarTheme(
            elevation: 0, centerTitle: true, scrolledUnderElevation: 0),
      ),
      builder: (context, child) {
        // Sits above the Navigator, so it sees touches on every screen
        // including pushed routes. Translucent and listener-only: it never
        // takes part in hit testing, so nothing below it behaves
        // differently. This is what lets [AppActivityService] tell "being
        // read" from "left open on the nightstand".
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => AppActivityService.instance.noteInteraction(),
          onPointerMove: (_) => AppActivityService.instance.noteInteraction(),
          child: GlobalSafeAreaWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const SplashScreen(),
    );
  }
}
