import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/models/promo_banner.dart';
import 'package:aykitap/core/models/streak.dart';
import 'package:aykitap/core/services/home_data_service.dart';
import 'package:aykitap/core/services/streak_service.dart';
import 'package:aykitap/modules/home/home_screen.dart';
import 'package:aykitap/modules/home/widgets/home_header.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Never emits, so [HomeConnectionBanner] never toggles state on its own —
/// this file isn't testing connectivity behavior.
class _FakeConnectivityPlatform extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void _installFakeSecureStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => null);
}

StreakOverview _overview() {
  final base = DateTime(2026, 1, 1);
  return StreakOverview(
    currentStreak: 1,
    bestStreak: 1,
    goalMinMinutes: 15,
    today:
        StreakDay(date: base, seconds: 0, minutes: 0, pages: 0, goalMet: false),
    week: List.generate(
      7,
      (i) => StreakWeekDay(
        weekday: i + 1,
        date: base.add(Duration(days: i)),
        seconds: 0,
        minutes: 0,
        pages: 0,
        goalMet: false,
      ),
    ),
    thisMonth: const StreakMonthSummary(
        month: '2026-01', pages: 0, minutes: 0, daysMet: 0),
    lastMonth: const StreakMonthSummary(
        month: '2025-12', pages: 0, minutes: 0, daysMet: 0),
    rewardRules: const [],
  );
}

Collection _collection(int id, {int queuePosition = 0}) => Collection(
      id: id,
      type: CollectionType.book,
      cardType: CollectionCardType.card1,
      name: 'Collection $id',
      queuePosition: queuePosition,
      books: [LibraryBook(id: id * 10, name: 'Book ${id * 10}')],
    );

PromoBanner _banner(int id, {int order = 0}) => PromoBanner(
      id: id,
      name: 'Banner $id',
      websiteImage: 'web_$id.png',
      mobileImage: 'mobile_$id.png',
      isActive: true,
      order: order,
    );

/// Counts, per widget runtime type, how many times [debugOnRebuildDirtyWidget]
/// fired for it — i.e. how many times that Element's `build()` actually ran.
/// No production code instrumentation needed: a [ValueListenableBuilder]'s
/// generic type argument is part of its `runtimeType`, so the three separate
/// `ValueListenableBuilder<...>`s [HomeScreen]/[BannerCarousel] use for
/// collections/banners/loading are distinguishable from each other purely by
/// type — this is what "header build count / banner build count /
/// collection-content build count" actually means in this codebase.
class _RebuildCounter {
  final counts = <Type, int>{};

  void attach() {
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      final type = element.widget.runtimeType;
      counts[type] = (counts[type] ?? 0) + 1;
    };
  }

  void detach() => debugOnRebuildDirtyWidget = null;

  int countOf(Type type) => counts[type] ?? 0;
}

// The Home-owned scopes under test, identified by the exact generic
// ValueListenableBuilder type each one is (see home_screen.dart /
// banner_carousel.dart).
final Type _headerType = HomeHeader;
final Type _collectionsScopeType = ValueListenableBuilder<List<Collection>?>;
final Type _bannersScopeType = ValueListenableBuilder<List<PromoBanner>?>;
final Type _loadingScopeType = ValueListenableBuilder<bool>;

void main() {
  late _RebuildCounter rebuilds;

  setUp(() {
    _installFakeSecureStorage();
    ConnectivityPlatform.instance = _FakeConnectivityPlatform();
    StreakService.instance.resetForTest();
    StreakService.instance.debugSeedOverviewForTesting(_overview());
    HomeDataService.instance.debugResetForTesting();
    rebuilds = _RebuildCounter()..attach();
  });

  tearDown(() {
    rebuilds.detach();
    HomeDataService.instance.debugResetForTesting();
    StreakService.instance.resetForTest();
  });

  Widget app() => MultiProvider(
        providers: [
          ChangeNotifierProvider<StreakService>.value(
              value: StreakService.instance),
        ],
        child: const MaterialApp(home: HomeScreen()),
      );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
      'a banner-only change does not rebuild the header or the collection scope',
      (tester) async {
    HomeDataService.instance.debugSeedForTesting(
      collections: [_collection(1)],
      banners: [_banner(1)],
    );
    await tester.pumpWidget(app());
    await settle(tester);

    final headerBefore = rebuilds.countOf(_headerType);
    final collectionsBefore = rebuilds.countOf(_collectionsScopeType);
    final bannersBefore = rebuilds.countOf(_bannersScopeType);

    HomeDataService.instance
        .debugSeedForTesting(banners: [_banner(1), _banner(2)]);
    await tester.pump();

    expect(rebuilds.countOf(_bannersScopeType), greaterThan(bannersBefore));
    expect(rebuilds.countOf(_headerType), headerBefore,
        reason: 'a banner change must not rebuild HomeHeader');
    expect(rebuilds.countOf(_collectionsScopeType), collectionsBefore,
        reason: 'a banner change must not rebuild the collection scope');
  });

  testWidgets(
      'a collections-only change does not rebuild the header or the banner scope',
      (tester) async {
    HomeDataService.instance.debugSeedForTesting(
      collections: [_collection(1)],
      banners: [_banner(1)],
    );
    await tester.pumpWidget(app());
    await settle(tester);

    final headerBefore = rebuilds.countOf(_headerType);
    final collectionsBefore = rebuilds.countOf(_collectionsScopeType);
    final bannersBefore = rebuilds.countOf(_bannersScopeType);

    HomeDataService.instance
        .debugSeedForTesting(collections: [_collection(1), _collection(2)]);
    await tester.pump();

    expect(rebuilds.countOf(_collectionsScopeType),
        greaterThan(collectionsBefore));
    expect(rebuilds.countOf(_headerType), headerBefore,
        reason: 'a collections change must not rebuild HomeHeader');
    expect(rebuilds.countOf(_bannersScopeType), bannersBefore,
        reason: 'a collections change must not rebuild the banner scope');
  });

  // Notification suppression for genuinely-unchanged refetched content (same
  // ids/fields/order, fresh List instances) is exercised directly against
  // HomeDataService's own listenables in home_data_service_test.dart —
  // [HomeDataService.debugSeedForTesting] is a raw test-only setter that
  // intentionally bypasses that equality gate (it exists to seed a known
  // shape quickly, not to exercise the gate itself), so it isn't the right
  // seam to re-verify that suppression through the widget tree here.

  testWidgets(
      'a loading change while empty only rebuilds the small retry scope, not the collection scope',
      (tester) async {
    HomeDataService.instance.debugSeedForTesting(
      collections: const [],
      banners: const [],
      loading: false,
    );
    await tester.pumpWidget(app());
    await settle(tester);

    final collectionsBefore = rebuilds.countOf(_collectionsScopeType);
    final loadingBefore = rebuilds.countOf(_loadingScopeType);

    HomeDataService.instance.debugSeedForTesting(loading: true);
    await tester.pump();

    expect(rebuilds.countOf(_loadingScopeType), greaterThan(loadingBefore));
    expect(rebuilds.countOf(_collectionsScopeType), collectionsBefore,
        reason: 'a loading change must not re-run the outer collections scope');
  });
}
