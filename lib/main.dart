import 'dart:async';

import 'package:aykitap/global_safe_area_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/layout/app_orientation_observer.dart';
import 'core/layout/app_orientation_policy.dart';
import 'core/layout/window_size_class.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/localization_delegates.dart';
import 'core/navigation/root_navigator.dart';
import 'core/services/account_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/app_activity_service.dart';
import 'core/services/app_bootstrap_service.dart';
import 'core/services/book_access_service.dart';
import 'core/services/book_download_service.dart';
import 'core/services/bookmarks_store.dart';
import 'core/services/downloaded_books_store.dart';
import 'core/services/downloaded_files_store.dart';
import 'core/services/home_data_service.dart';
import 'core/services/last_read_book_store.dart';
import 'core/services/notes_store.dart';
import 'core/services/own_books_store.dart';
import 'core/services/premium_access_service.dart';
import 'core/services/purchase_mode_service.dart';
import 'core/services/purchased_books_store.dart';
import 'core/services/reading_books_store.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/services/streak_service.dart';
import 'core/services/subscription_service.dart';
import 'core/theme/theme_controller.dart';
import 'modules/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Default is 1000 images / 100MB. Covers now decode at their real
  // per-axis display size (see NetworkCoverImage) instead of the larger of
  // width/height, so each cached entry is a fraction of what it used to be
  // — a bigger *count* budget than the default still helps (Home, Library
  // and Search all keep many covers resident at once), but a bigger *byte*
  // budget doesn't need to compensate for oversized entries anymore. 700
  // images holds noticeably more real covers than the previous 3000-entry
  // budget did before this fix, at under half the memory ceiling — the
  // difference matters most on mid-range Android, where a large resident
  // image cache is a common source of GC pauses and scroll jank.
  PaintingBinding.instance.imageCache.maximumSize = 700;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20;
  // Locks portrait immediately, before the first frame — there's no
  // MediaQuery yet to read a real window size from, so this primes
  // AppOrientationPolicy with the same compact/no-reader default it starts
  // with anyway. AppOrientationObserver (in this widget's `builder`) takes
  // over from here once the tree is up, so this is the *only* direct
  // SystemChrome.setPreferredOrientations call left outside that policy —
  // see app_orientation_policy.dart.
  AppOrientationPolicy.instance.updateWindow(const WindowSizeClass(
    width: WindowWidthClass.compact,
    size: Size.zero,
    verticalHinge: null,
  ));
  // Hide Android's 3-button navigation bar entirely (keep the status bar).
  // A swipe up from the bottom edge still reveals it temporarily.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top]);
  // The only startup work genuinely awaited ahead of `runApp()` — theme and
  // locale are the two things a user would actually *see* go wrong (a flash
  // of the wrong theme, or a frame in the wrong language) if they weren't
  // ready yet. Everything else (analytics, push, RevenueCat, the reader's
  // home-screen widgets, the device fingerprint, foreground-time tracking)
  // starts only after the first frame — see [AppBootstrapService].
  await AppBootstrapService.instance.runBeforeFirstFrame();
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
        ChangeNotifierProvider<RevenueCatService>.value(
            value: RevenueCatService.instance),
        ChangeNotifierProvider<PremiumAccessService>.value(
            value: PremiumAccessService.instance),
        ChangeNotifierProvider<PurchaseModeService>.value(
            value: PurchaseModeService.instance),
      ],
      child: const AykitapApp(),
    ),
  );
  // Kicked off after `runApp()`, not before — its own kick-off is
  // synchronous work (building the `Future.wait` list below), and nothing
  // about it should run ahead of the call that actually schedules the
  // first frame.
  unawaited(AppBootstrapService.instance.runAfterFirstFrame());
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
        return AppOrientationObserver(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => AppActivityService.instance.noteInteraction(),
            onPointerMove: (_) => AppActivityService.instance.noteInteraction(),
            child:
                GlobalSafeAreaWrapper(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
