import 'dart:async';

import 'package:flutter/foundation.dart';
import '../localization/app_locale.dart';
import '../models/collection.dart';
import '../models/library_book.dart';
import '../models/promo_banner.dart';
import 'banner_api_service.dart';
import 'collection_api_service.dart';

/// Holds Home's `GET /collections/all` + `GET /banners` data so both can be
/// prefetched starting at the splash screen ([SplashScreen._bootstrap] fires
/// [load] without awaiting it) — by the time the user actually reaches Home,
/// the network round-trip is already done or well underway, instead of only
/// starting once [HomeScreen] itself mounts.
///
/// [collectionsListenable], [bannersListenable] and [loadingListenable] are
/// each their own [ValueListenable] rather than one combined
/// [ChangeNotifier] signal, so [HomeScreen] and [BannerCarousel] can listen
/// to only the slice they actually render with — a banner refresh no longer
/// rebuilds Home's collection sections and vice versa. A refetch that
/// resolves to content identical to what's already held (same ids, same
/// fields, same order) leaves the notifier's value untouched, so nothing
/// downstream rebuilds at all — see the `_...Equal` helpers below, which
/// exist only because [Collection]/[PromoBanner]/[LibraryBook] have no
/// [Object.==] override of their own (deliberately not added to those
/// models here — they're relied on well beyond Home, and giving them a
/// wide-reaching identity change is a bigger blast radius than a comparison
/// kept local to this file). [notifyListeners] still fires alongside the
/// notifiers for any other, currently nonexistent, whole-service watcher.
class HomeDataService extends ChangeNotifier {
  HomeDataService._({
    Future<List<Collection>> Function()? fetchCollections,
    Future<List<PromoBanner>> Function()? fetchBanners,
  })  : _fetchCollections =
            fetchCollections ?? CollectionApiService.getCollections,
        _fetchBanners = fetchBanners ?? BannerApiService.getBanners {
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

  /// Builds an isolated instance with injected fetchers instead of the real
  /// `GET /collections/all` / `GET /banners` calls, so [load]/[reload]/
  /// [refreshInBackground]'s notification-suppression and generation-guard
  /// logic can be unit tested without a fake Dio transport. Never touches
  /// [instance] — production code always goes through the real singleton.
  @visibleForTesting
  factory HomeDataService.forTesting({
    required Future<List<Collection>> Function() fetchCollections,
    required Future<List<PromoBanner>> Function() fetchBanners,
  }) =>
      HomeDataService._(
          fetchCollections: fetchCollections, fetchBanners: fetchBanners);

  final Future<List<Collection>> Function() _fetchCollections;
  final Future<List<PromoBanner>> Function() _fetchBanners;

  final ValueNotifier<List<Collection>?> _collections = ValueNotifier(null);
  final ValueNotifier<List<PromoBanner>?> _banners = ValueNotifier(null);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  ValueListenable<List<Collection>?> get collectionsListenable => _collections;
  ValueListenable<List<PromoBanner>?> get bannersListenable => _banners;
  ValueListenable<bool> get loadingListenable => _loadingNotifier;

  List<Collection>? get collections => _collections.value;
  List<PromoBanner>? get banners => _banners.value;

  /// Bumped by [reload] so a fetch that was already in flight when the
  /// language changed can't write its now stale-language result over the
  /// newer one.
  int _generation = 0;

  bool get isLoaded => collections != null && banners != null;
  bool get isLoading => _loadingNotifier.value;

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
    if (isLoading || isLoaded) return;
    _setLoading(true);
    final generation = _generation;
    await Future.wait([_loadCollections(generation), _loadBanners(generation)]);
    // A [reload] came in while we were waiting; its own `load` owns
    // `_loading` and will notify once it settles.
    if (generation != _generation) return;
    _setLoading(false);
    notifyListeners();
  }

  Future<void> _loadCollections(
    int generation, {
    bool preserveOnError = false,
  }) async {
    List<Collection> result;
    try {
      result = await _fetchCollections();
    } catch (_) {
      if (preserveOnError) return;
      result = const [];
    }
    if (generation == _generation) _setCollections(result);
  }

  Future<void> _loadBanners(
    int generation, {
    bool preserveOnError = false,
  }) async {
    List<PromoBanner> result;
    try {
      result = await _fetchBanners();
    } catch (_) {
      if (preserveOnError) return;
      result = const [];
    }
    if (generation == _generation) _setBanners(result);
  }

  /// Skips the assignment entirely when [value] matches what's already held
  /// — the actual "don't notify on unchanged data" gate, since
  /// [ValueNotifier] can only compare by `==`, which is reference equality
  /// for a freshly-deserialized [List].
  void _setCollections(List<Collection> value) {
    if (_collectionsEqual(_collections.value, value)) return;
    _collections.value = List.unmodifiable(value);
  }

  void _setBanners(List<PromoBanner> value) {
    if (_promoBannersEqual(_banners.value, value)) return;
    _banners.value = List.unmodifiable(value);
  }

  void _setLoading(bool value) {
    if (_loadingNotifier.value == value) return;
    _loadingNotifier.value = value;
  }

  /// Clears every field back to a fresh instance's defaults. [instance] is
  /// this app's process-lifetime singleton, so a widget test exercising
  /// [HomeScreen]/[BannerCarousel] against it needs a way to undo state
  /// between cases — there is no other way to get a clean [HomeDataService]
  /// in a test process. Never called from production code.
  @visibleForTesting
  void debugResetForTesting() {
    _collections.value = null;
    _banners.value = null;
    _loadingNotifier.value = false;
  }

  /// Test-only seed — sets [collections]/[banners]/[isLoading] directly
  /// with no network call, so a widget test can put [HomeScreen] straight
  /// into whichever state it needs to verify. Never called from production
  /// code.
  @visibleForTesting
  void debugSeedForTesting({
    List<Collection>? collections,
    List<PromoBanner>? banners,
    bool? loading,
  }) {
    if (collections != null) {
      _collections.value = List.unmodifiable(collections);
    }
    if (banners != null) _banners.value = List.unmodifiable(banners);
    if (loading != null) _loadingNotifier.value = loading;
  }

  /// Forces a fresh fetch regardless of [isLoaded] — a language switch, or a
  /// future pull-to-refresh on Home. Clearing the lists first puts Home back
  /// on its shimmer skeleton while the new-language data is on the wire.
  Future<void> reload() async {
    _generation++;
    // An in-flight `load` is now superseded and will bail out without
    // clearing this, so take ownership of the flag here.
    _setLoading(false);
    _collections.value = null;
    _banners.value = null;
    notifyListeners();
    await load();
  }

  /// Refreshes stale Home data after connectivity returns without replacing
  /// the usable cached shelves with a shimmer or an empty error state.
  Future<void> refreshInBackground() async {
    if (isLoading) return;
    _setLoading(true);
    final generation = ++_generation;
    await Future.wait([
      _loadCollections(generation, preserveOnError: true),
      _loadBanners(generation, preserveOnError: true),
    ]);
    if (generation != _generation) return;
    _setLoading(false);
    notifyListeners();
  }
}

// ---- Local, non-model-invasive deep-equality helpers ----------------------
//
// [Collection], [PromoBanner], [LibraryBook] and [LibraryBookAuthor]
// intentionally keep no [Object.==] override — see the class doc above.
// These walk every field so a freshly-deserialized response carrying the
// exact same content as what's already held is recognized as unchanged.

bool _promoBannersEqual(List<PromoBanner>? a, List<PromoBanner>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_promoBannerEqual(a[i], b[i])) return false;
  }
  return true;
}

bool _promoBannerEqual(PromoBanner a, PromoBanner b) =>
    a.id == b.id &&
    a.name == b.name &&
    a.websiteImage == b.websiteImage &&
    a.mobileImage == b.mobileImage &&
    a.link == b.link &&
    a.bookId == b.bookId &&
    a.isActive == b.isActive &&
    a.order == b.order;

bool _collectionsEqual(List<Collection>? a, List<Collection>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_collectionEqual(a[i], b[i])) return false;
  }
  return true;
}

bool _collectionEqual(Collection a, Collection b) =>
    a.id == b.id &&
    a.type == b.type &&
    a.cardType == b.cardType &&
    a.name == b.name &&
    a.subTitle == b.subTitle &&
    a.image == b.image &&
    a.queuePosition == b.queuePosition &&
    _libraryBooksEqual(a.books, b.books) &&
    _libraryBookAuthorsEqual(a.authors, b.authors);

bool _libraryBooksEqual(List<LibraryBook> a, List<LibraryBook> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_libraryBookEqual(a[i], b[i])) return false;
  }
  return true;
}

bool _libraryBookEqual(LibraryBook a, LibraryBook b) =>
    a.id == b.id &&
    a.name == b.name &&
    a.description == b.description &&
    a.image == b.image &&
    a.age == b.age &&
    a.year == b.year &&
    a.pageCount == b.pageCount &&
    a.price == b.price &&
    a.progress == b.progress &&
    _libraryBookAuthorsEqual(a.authors, b.authors);

bool _libraryBookAuthorsEqual(
    List<LibraryBookAuthor>? a, List<LibraryBookAuthor>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_libraryBookAuthorEqual(a[i], b[i])) return false;
  }
  return true;
}

bool _libraryBookAuthorEqual(LibraryBookAuthor a, LibraryBookAuthor b) =>
    a.id == b.id && a.name == b.name && a.image == b.image;
