part of 'home_screen.dart';

/// Collection-section rendering for [_HomeScreenState]: grouping collections
/// into rows by shared `queue_position`, and dispatching each to the right
/// visual (genre shelf row, ranked shelf, series card, author avatar row, or
/// plain horizontal book section).
extension _HomeScreenSections on _HomeScreenState {
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
      case CollectionCardType.card4:
        return SizedBox(width: 360, child: CatalogNumberedBookSection(collection: collection, compact: true));
      case CollectionCardType.card2:
        return Container(padding: const EdgeInsets.only(bottom: 20), width: 320, child: CatalogRankShelfCard(collection: collection, fillHeight: true));
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
  ///
  /// [sectionDelay] is this collection's own [StaggerFadeIn] entrance delay
  /// (the caller already wraps the whole entry in one) — threaded through
  /// to whichever card-row builder needs to hand it to its own *nested*
  /// [StaggerFadeIn]s as [StaggerFadeIn.extraDelay], so the cards inside a
  /// row cascade in step with the row's own reveal instead of racing ahead
  /// of it. See [StaggerFadeIn.extraDelay]'s doc comment for why that
  /// matters.
  Widget _buildCollectionEntry(BuildContext context, Collection collection, Duration sectionDelay) {
    if (collection.type == CollectionType.author) {
      final authors = collection.authors ?? const [];
      if (authors.isEmpty) return const SizedBox.shrink();
      return _buildCatalogAuthorsRow(collection, authors);
    }
    if (collection.books.isEmpty) return const SizedBox.shrink();
    switch (collection.cardType) {
      case CollectionCardType.card4:
        return CatalogNumberedBookSection(collection: collection);
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
        return _buildCatalogBookSection(context, collection, sectionDelay);
    }
  }

  Widget _buildCatalogBookSection(BuildContext context, Collection collection, Duration sectionDelay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: collection.name,
          subtitle: collection.subTitle,
          seeAllLabel: HomeStrings.seeAll,
          onSeeAll: () => context.pushFade(CatalogCollectionBooksScreen(title: collection.name, books: collection.books)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collection.books.length,
            itemBuilder: (_, i) => StaggerFadeIn(
              index: i,
              extraDelay: sectionDelay,
              // Slides in from the right — the direction this row scrolls
              // toward — rather than the default upward slide.
              slideFrom: const Offset(24, 0),
              child: CatalogBookCard(
                book: collection.books[i],
                heroTag: AppHeroTags.homeCollectionBookCover(
                  collection.id,
                  collection.books[i].id,
                ),
              ),
            ),
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
          // Tall enough for the 88-diameter ring avatar, up to two lines of
          // name, and the card's own vertical padding — see
          // [CatalogAuthorAvatar].
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: authors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => CatalogAuthorAvatar(
              authorId: authors[i].id,
              name: authors[i].name,
              image: authors[i].image,
            ),
          ),
        ),
      ],
    );
  }
}
