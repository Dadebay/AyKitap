import 'package:aykitap/core/models/collection.dart';
import 'package:aykitap/core/models/library_book.dart';
import 'package:aykitap/core/models/promo_banner.dart';
import 'package:aykitap/core/services/home_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

Collection _collection(int id,
        {int queuePosition = 0, List<LibraryBook>? books}) =>
    Collection(
      id: id,
      type: CollectionType.book,
      cardType: CollectionCardType.card1,
      name: 'Collection $id',
      queuePosition: queuePosition,
      books: books ?? [LibraryBook(id: id * 10, name: 'Book ${id * 10}')],
    );

PromoBanner _banner(int id, {int order = 0}) => PromoBanner(
      id: id,
      name: 'Banner $id',
      websiteImage: 'web_$id.png',
      mobileImage: 'mobile_$id.png',
      isActive: true,
      order: order,
    );

void main() {
  group('HomeDataService.load', () {
    test('fetches collections and banners in parallel, not sequentially',
        () async {
      final collectionsStarted = <String>[];
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          collectionsStarted.add('collections-start');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return [_collection(1)];
        },
        fetchBanners: () async {
          collectionsStarted.add('banners-start');
          return [_banner(1)];
        },
      );

      await service.load();

      // Both fetchers were invoked before either had a chance to finish —
      // proof they ran concurrently via Future.wait, not one after another.
      expect(collectionsStarted, ['collections-start', 'banners-start']);
      expect(service.collections, hasLength(1));
      expect(service.banners, hasLength(1));
    });

    test('is idempotent — a second call while loading does not refetch',
        () async {
      var collectionFetchCount = 0;
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          collectionFetchCount++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return [_collection(1)];
        },
        fetchBanners: () async => [_banner(1)],
      );

      final first = service.load();
      final second = service.load(); // Already loading — must be a no-op.
      await Future.wait([first, second]);

      expect(collectionFetchCount, 1);
    });

    test('a failed endpoint resolves to an empty list, not a stuck null',
        () async {
      final service = HomeDataService.forTesting(
        fetchCollections: () async => throw Exception('network down'),
        fetchBanners: () async => [_banner(1)],
      );

      await service.load();

      expect(service.collections, isEmpty);
      expect(service.banners, hasLength(1));
      expect(service.isLoaded, isTrue);
    });

    test('hasNoContent is true only once both endpoints settle empty',
        () async {
      final service = HomeDataService.forTesting(
        fetchCollections: () async => const [],
        fetchBanners: () async => const [],
      );

      expect(service.hasNoContent, isFalse);
      await service.load();
      expect(service.hasNoContent, isTrue);
    });
  });

  group('HomeDataService notification suppression', () {
    test(
        'collectionsListenable does not fire when refetched content is identical',
        () async {
      var fetchCount = 0;
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          fetchCount++;
          // A fresh List<Collection> instance every call, same content —
          // exactly what a repeat network response looks like.
          return [_collection(1)];
        },
        fetchBanners: () async => [_banner(1)],
      );
      await service.load();
      final firedAfterFirstLoad = <List<Collection>?>[];
      service.collectionsListenable
          .addListener(() => firedAfterFirstLoad.add(service.collections));

      await service.refreshInBackground();

      expect(fetchCount, 2);
      expect(firedAfterFirstLoad, isEmpty,
          reason: 'same collection content must not renotify listeners');
    });

    test('collectionsListenable fires when refetched content actually differs',
        () async {
      var callCount = 0;
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          callCount++;
          return callCount == 1
              ? [_collection(1)]
              : [_collection(1), _collection(2)];
        },
        fetchBanners: () async => [_banner(1)],
      );
      await service.load();
      var notifyCount = 0;
      service.collectionsListenable.addListener(() => notifyCount++);

      await service.refreshInBackground();

      expect(notifyCount, 1);
      expect(service.collections, hasLength(2));
    });

    test('bannersListenable does not fire when refetched banners are identical',
        () async {
      final service = HomeDataService.forTesting(
        fetchCollections: () async => [_collection(1)],
        fetchBanners: () async => [_banner(1), _banner(2)],
      );
      await service.load();
      var notifyCount = 0;
      service.bannersListenable.addListener(() => notifyCount++);

      await service.refreshInBackground();

      expect(notifyCount, 0);
    });

    test('a banner change does not fire the collections listenable', () async {
      var bannerCall = 0;
      final service = HomeDataService.forTesting(
        fetchCollections: () async => [_collection(1)],
        fetchBanners: () async {
          bannerCall++;
          return bannerCall == 1 ? [_banner(1)] : [_banner(1), _banner(2)];
        },
      );
      await service.load();
      var collectionsNotified = 0;
      service.collectionsListenable.addListener(() => collectionsNotified++);

      await service.refreshInBackground();

      expect(service.banners, hasLength(2));
      expect(collectionsNotified, 0);
    });
  });

  group('HomeDataService.reload', () {
    test('clears content to null before the new fetch resolves', () async {
      final service = HomeDataService.forTesting(
        fetchCollections: () async => [_collection(1)],
        fetchBanners: () async => [_banner(1)],
      );
      await service.load();
      expect(service.collections, isNotNull);

      final reloadFuture = service.reload();
      // Synchronously after calling reload (before awaiting), the clear to
      // null — and its own notification — has already happened.
      expect(service.collections, isNull);
      expect(service.banners, isNull);
      await reloadFuture;
      expect(service.collections, isNotNull);
    });

    test('a stale in-flight fetch cannot overwrite a newer reload result',
        () async {
      var call = 0;
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          call++;
          if (call == 1) {
            // The first (stale) fetch resolves slowly, after the reload
            // below has already bumped the generation.
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return [_collection(999)];
          }
          return [_collection(1)];
        },
        fetchBanners: () async => [_banner(1)],
      );

      final firstLoad = service.load();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final reloadFuture = service.reload();
      await Future.wait([firstLoad, reloadFuture]);

      expect(service.collections,
          isNot(contains(predicate<Collection>((c) => c.id == 999))));
      expect(service.collections!.single.id, 1);
    });
  });

  group('HomeDataService.refreshInBackground', () {
    test('preserves old collections when the refetch errors', () async {
      var shouldFail = false;
      final service = HomeDataService.forTesting(
        fetchCollections: () async {
          if (shouldFail) throw Exception('offline');
          return [_collection(1)];
        },
        fetchBanners: () async => [_banner(1)],
      );
      await service.load();
      expect(service.collections, hasLength(1));

      shouldFail = true;
      await service.refreshInBackground();

      // refreshInBackground uses preserveOnError — a failed refetch must
      // not replace the still-usable cached shelves with an empty list.
      expect(service.collections, hasLength(1));
    });

    test('one endpoint erroring does not lose the other\'s successful data',
        () async {
      var bannersShouldFail = false;
      final service = HomeDataService.forTesting(
        fetchCollections: () async => [_collection(1)],
        fetchBanners: () async {
          if (bannersShouldFail) throw Exception('offline');
          return [_banner(1)];
        },
      );
      await service.load();

      bannersShouldFail = true;
      await service.refreshInBackground();

      expect(service.banners, hasLength(1),
          reason: 'banners must keep their last good value, not go empty');
      expect(service.collections, hasLength(1));
    });
  });

  test('loadingListenable does not fire twice for the same value', () async {
    final service = HomeDataService.forTesting(
      fetchCollections: () async => [_collection(1)],
      fetchBanners: () async => [_banner(1)],
    );
    final loadingValues = <bool>[];
    service.loadingListenable
        .addListener(() => loadingValues.add(service.isLoading));

    await service.load();

    // true (fetch started) then false (settled) — never a duplicate of the
    // same value back to back.
    expect(loadingValues, [true, false]);
  });
}
