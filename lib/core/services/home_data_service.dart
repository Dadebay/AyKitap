import 'package:flutter/foundation.dart';
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
  HomeDataService._();
  static final instance = HomeDataService._();

  List<Collection>? collections;
  List<PromoBanner>? banners;
  bool _loading = false;

  bool get isLoaded => collections != null && banners != null;

  /// Idempotent: a fetch already in flight or already settled is a no-op,
  /// so both the splash screen's kick-off and Home's own fallback call (in
  /// case Home is reached without going through splash, e.g. a hot reload)
  /// can call this freely without racing each other.
  Future<void> load() async {
    if (_loading || isLoaded) return;
    _loading = true;
    await Future.wait([_loadCollections(), _loadBanners()]);
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadCollections() async {
    try {
      collections = await CollectionApiService.getCollections();
    } catch (_) {
      collections = const [];
    }
  }

  Future<void> _loadBanners() async {
    try {
      banners = await BannerApiService.getBanners();
    } catch (_) {
      banners = const [];
    }
  }

  /// Forces a fresh fetch regardless of [isLoaded] — e.g. a future
  /// pull-to-refresh on Home.
  Future<void> reload() async {
    collections = null;
    banners = null;
    notifyListeners();
    await load();
  }
}
