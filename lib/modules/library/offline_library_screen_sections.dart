part of 'offline_library_screen.dart';

/// [_OfflineLibraryScreenState]'s sliver layout: a "Ýüklenenler" section for
/// downloaded catalogue books, then an "Öz Kitaplarym" one for local
/// imports — split out of offline_library_screen.dart to keep that file
/// under the 200-line limit.
extension _OfflineLibraryScreenSections on _OfflineLibraryScreenState {
  List<Widget> _buildSlivers({
    required List<OwnBook> ownBooks,
    required List<LibraryBook> catalogBooks,
  }) {
    return [
      if (catalogBooks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(title: LibraryStrings.tabDownloaded),
        ),
        _bookGrid(
          itemCount: catalogBooks.length,
          itemBuilder: (context, i) => LibraryBookCover(
            book: catalogBooks[i],
            heroShelf: 'offline-downloaded',
            onTap: () => _openCatalogBook(catalogBooks[i]),
          ),
        ),
      ],
      if (ownBooks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(title: LibraryStrings.tabOwnBooks),
        ),
        _bookGrid(
          itemCount: ownBooks.length,
          itemBuilder: (context, i) => OwnBookSpineCover(
            book: ownBooks[i],
            onTap: () => _openOwnBook(ownBooks[i]),
            borderRadius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            wrapAspectRatio: false,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
    ];
  }

  SliverPadding _bookGrid({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      sliver: SliverGrid(
        delegate:
            SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }
}
