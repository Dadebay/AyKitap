import 'dart:async';

import 'package:flutter/foundation.dart';
import '../localization/app_locale.dart';
import '../models/collection.dart';
import '../models/promo_banner.dart';
import 'banner_api_service.dart';
import 'collection_api_service.dart';

/// Holds Home's `GET /collections/all` + `GET /banners` data so both can be
/// prefetched starting at the splash screen ([SplashScreen._bootstrap] fires
/// [load] without awaiting it) — by the time the user actually reaches Home,
/// the network round-trip is already done or well underway, instead of only
/// starting once [HomeScreen] itself mounts.
///
/// [HomeScreen] and [BannerCarousel] both just watch this via `Provider`
/// rather than fetching on their own; each field is null until its own
/// fetch settles (success or failure — a failure still resolves to `[]` so
/// the UI has a definite "empty" state to render instead of staying null
/// forever), which is what tells each of them to swap its shimmer skeleton
/// for real content.
class HomeDataService extends ChangeNotifier {
  HomeDataService._() {
    // Section headers ("Täze gelenler", ...) and book titles come back in
    // whatever language `Accept-Language` asked for (see [DioClient]), so
    // everything held here goes stale the moment the user switches language.
    // Listening here rather than in [HomeScreen] means the refetch happens
    // even while Home is off-screen (the switch lives in Settings, on
    // another tab), and [BannerCarousel] — which watches this same service —
    // gets refreshed by the same pass.
    AppLocale.instance.addListener(() => unawaited(reload()));
  }
  static final instance = HomeDataService._();

  List<Collection>? collections;
  List<PromoBanner>? banners;
  bool _loading = false;

  /// Bumped by [reload] so a fetch that was already in flight when the
  /// language changed can't write its now stale-language result over the
  /// newer one.
  int _generation = 0;

  bool get isLoaded => collections != null && banners != null;
  bool get isLoading => _loading;

  /// Both endpoints settled but neither produced anything to render. This is
  /// normally a lost connection (errors intentionally become empty lists),
  /// and lets Home offer a clear retry affordance instead of looking broken.
  bool get hasNoContent =>
      collections != null &&
      banners != null &&
      collections!.isEmpty &&
      banners!.isEmpty;

  /// Idempotent: a fetch already in flight or already settled is a no-op,
  /// so both the splash screen's kick-off and Home's own fallback call (in
  /// case Home is reached without going through splash, e.g. a hot reload)
  /// can call this freely without racing each other.
  Future<void> load() async {
    if (_loading || isLoaded) return;
    _loading = true;
    final generation = _generation;
    await Future.wait([_loadCollections(generation), _loadBanners(generation)]);
    // A [reload] came in while we were waiting; its own `load` owns
    // `_loading` and will notify once it settles.
    if (generation != _generation) return;
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCollections(
    int generation, {
    bool preserveOnError = false,
  }) async {
    List<Collection> result;
    try {
      result = await CollectionApiService.getCollections();
    } catch (_) {
      if (preserveOnError) return;
      result = const [];
    }
    if (generation == _generation) collections = result;
  }

  Future<void> _loadBanners(
    int generation, {
    bool preserveOnError = false,
  }) async {
    List<PromoBanner> result;
    try {
      result = await BannerApiService.getBanners();
    } catch (_) {
      if (preserveOnError) return;
      result = const [];
    }
    if (generation == _generation) banners = result;
  }

  /// Forces a fresh fetch regardless of [isLoaded] — a language switch, or a
  /// future pull-to-refresh on Home. Clearing the lists first puts Home back
  /// on its shimmer skeleton while the new-language data is on the wire.
  Future<void> reload() async {
    _generation++;
    // An in-flight `load` is now superseded and will bail out without
    // clearing this, so take ownership of the flag here.
    _loading = false;
    collections = null;
    banners = null;
    notifyListeners();
    await load();
  }

  /// Refreshes stale Home data after connectivity returns without replacing
  /// the usable cached shelves with a shimmer or an empty error state.
  Future<void> refreshInBackground() async {
    if (_loading) return;
    _loading = true;
    final generation = ++_generation;
    await Future.wait([
      _loadCollections(generation, preserveOnError: true),
      _loadBanners(generation, preserveOnError: true),
    ]);
    if (generation != _generation) return;
    _loading = false;
    notifyListeners();
  }
}
