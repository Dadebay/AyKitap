import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/collection.dart';
import '../../core/models/library_book.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/home_data_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/section_header.dart';
import '../streak/streak_screen.dart';
import 'catalog_collection_books_screen.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/catalog_author_avatar.dart';
import 'widgets/catalog_book_card.dart';
import 'widgets/catalog_rank_shelf_card.dart';
import 'widgets/catalog_series_card.dart';
import 'widgets/home_header.dart';
import 'widgets/home_shimmer.dart';

/// Home tab — every section below the header/banner comes straight from
/// `GET /collections/all` ([HomeDataService], prefetched starting at the
/// splash screen); nothing here is mock catalogue data. Search still runs
/// on the mock catalogue ([MockData]) — that migration is a separate,
/// much larger piece of work.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = HomeStrings.defaultReaderName;

  @override
  void initState() {
    super.initState();
    _loadName();
    StreakService.instance.load();
    // Fallback only — the splash screen already kicked this off. Idempotent,
    // so this is a no-op on the normal path (already loading/loaded by the
    // time Home mounts).
    HomeDataService.instance.load();
  }

  Future<void> _loadName() async {
    final name = await AuthSession.getName();
    if (mounted && name != null && name.isNotEmpty) setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final homeData = context.watch<HomeDataService>();
    final collections = homeData.collections;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              name: _name,
              onStreakTap: () => context.push(const StreakScreen()),
            ),
          ),
          const SliverToBoxAdapter(child: BannerCarousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (collections == null)
            const SliverToBoxAdapter(child: HomeShimmer())
          else if (homeData.hasNoContent)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _HomeReloadState(
                loading: homeData.isLoading,
                onReload: HomeDataService.instance.reload,
              ),
            )
          else
            // "Täze gelenler", "Hepdelik iň köp okalanlar", "Rus Ýazarlar",
            // ... — one stacked straight from `GET /collections/all`, in
            // whatever order/count the backend sends. Consecutive entries
            // that share the same `queue_position` (e.g. "Biznes / Maliýe",
            // "Şahsy Ösüş", "Psihologiýa", "Liderlik" all at 41) are meant to
            // sit side by side as one horizontal row instead of each getting
            // its own stacked section — see [_groupByQueuePosition].
            for (final group in _groupByQueuePosition(collections))
              SliverToBoxAdapter(
                child: group.length > 1 ? _buildGenreShelfRow(context, group) : _buildCollectionEntry(context, group.first),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Splits [collections] into consecutive runs that share one
  /// `queue_position` — most positions are unique (a run of 1, rendered
  /// exactly as before), but the backend uses a shared position to mean
  /// "these belong in the same horizontal row" (e.g. a set of genre
  /// shelves). Only consecutive entries are grouped — the backend already
  /// sends same-position rows next to each other, so this doesn't need to
  /// re-sort or hunt through the whole list.
  List<List<Collection>> _groupByQueuePosition(List<Collection> collections) {
    final groups = <List<Collection>>[];
    for (final c in collections) {
      if (groups.isNotEmpty && groups.last.first.queuePosition == c.queuePosition) {
        groups.last.add(c);
      } else {
        groups.add([c]);
      }
    }
    return groups;
  }

  Widget _buildGenreShelfRow(BuildContext context, List<Collection> group) {
    final shelves = group.where((c) => c.type == CollectionType.book && c.books.isNotEmpty).toList();
    if (shelves.isEmpty) return const SizedBox.shrink();
    final hasRankShelf = shelves.any((c) => c.cardType == CollectionCardType.card2);
    final rowHeight = hasRankShelf ? 460.0 : 300.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: SizedBox(
        height: rowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: shelves.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _buildGenreShelfTile(shelves[i]),
        ),
      ),
    );
  }

  Widget _buildGenreShelfTile(Collection collection) {
    switch (collection.cardType) {
      case CollectionCardType.card2:
        return Container(padding: const EdgeInsets.only(bottom: 20), width: 320, child: CatalogRankShelfCard(collection: collection));
      case CollectionCardType.card3:
        return SizedBox(width: 320, child: CatalogSeriesCard(collection: collection));
      case CollectionCardType.card1:
        return SizedBox(width: 320, child: CatalogSeriesCard(collection: collection));
    }
  }

  /// Dispatches one [Collection] to the right visual: [CollectionType.author]
  /// renders its `authors` as an avatar row regardless of `card_type` (a
  /// themed author set has nothing to rank/series-ify); otherwise
  /// `card_type` picks between a plain book row, a ranked-shelf card, or a
  /// big series-style card. Unknown/empty cases collapse to nothing rather
  /// than showing an empty header.
  Widget _buildCollectionEntry(BuildContext context, Collection collection) {
    if (collection.type == CollectionType.author) {
      final authors = collection.authors ?? const [];
      if (authors.isEmpty) return const SizedBox.shrink();
      return _buildCatalogAuthorsRow(collection, authors);
    }
    if (collection.books.isEmpty) return const SizedBox.shrink();
    switch (collection.cardType) {
      case CollectionCardType.card2:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: CatalogRankShelfCard(collection: collection),
        );
      case CollectionCardType.card3:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: SizedBox(height: 380, child: CatalogSeriesCard(collection: collection)),
        );
      case CollectionCardType.card1:
        return _buildCatalogBookSection(context, collection);
    }
  }

  Widget _buildCatalogBookSection(BuildContext context, Collection collection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: collection.name,
          subtitle: collection.subTitle,
          seeAllLabel: HomeStrings.seeAll,
          onSeeAll: () => context.push(CatalogCollectionBooksScreen(title: collection.name, books: collection.books)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collection.books.length,
            itemBuilder: (_, i) => CatalogBookCard(book: collection.books[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogAuthorsRow(Collection collection, List<LibraryBookAuthor> authors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: collection.name, subtitle: collection.subTitle),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => CatalogAuthorAvatar(author: authors[i]),
          ),
        ),
      ],
    );
  }
}

/// Recoverable state for Home's two server-driven data sources. Keeping this
/// inside the scroll view means the header remains visible while the reader
/// retries, rather than presenting an abruptly blank full-page error.
class _HomeReloadState extends StatelessWidget {
  const _HomeReloadState({required this.loading, required this.onReload});

  final bool loading;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 128),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded,
                    color: AppColors.primary, size: 27),
              ),
              const SizedBox(height: 16),
              Text(
                HomeStrings.reloadTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                HomeStrings.reloadBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey2, fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onReload,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(HomeStrings.reload),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.65),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
