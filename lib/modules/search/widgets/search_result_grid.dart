import 'package:flutter/material.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_hero_tags.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/catalog_book_card.dart';
import '../../home/widgets/stagger_fade_in.dart';

/// Shared by [SearchScreen]'s search-results and discover grids — three
/// columns of covers, plus a spinner row at the bottom while the next page
/// is in flight. A [CustomScrollView] rather than a plain [GridView.builder]
/// so that spinner can sit as its own sliver below the grid instead of
/// needing an off-by-one extra grid cell for it.
class SearchResultGrid extends StatelessWidget {
  static const _crossAxisCount = 3;

  final List<LibraryBook> books;
  final EdgeInsets padding;
  final bool loadingMore;

  const SearchResultGrid(
      {super.key,
      required this.books,
      required this.padding,
      required this.loadingMore});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            // Staggered by row (see [CatalogCollectionBooksScreen] for the
            // same reasoning) — but unlike that one-shot grid, this one
            // grows via infinite-scroll `loadMore`, and [StaggerFadeIn]
            // keeps every cell it ever animates alive (that's how it avoids
            // replaying on scroll-back). On a long search/discover session
            // that's an unbounded number of kept-alive cards — acceptable
            // for now, but worth revisiting with a non-keepAlive entrance
            // if that turns out to matter on real devices.
            delegate: SliverChildBuilderDelegate(
              (_, i) => StaggerFadeIn(
                index: i ~/ _crossAxisCount,
                child: CatalogBookCard(
                    book: books[i],
                    heroTag: AppHeroTags.catalogBookCover(books[i].id),
                    width: double.infinity,
                    coverHeight: 170,
                    margin: EdgeInsets.zero),
              ),
              childCount: books.length,
            ),
          ),
        ),
        if (loadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
