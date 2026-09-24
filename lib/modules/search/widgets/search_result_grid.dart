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
  static const _crossAxisSpacing = 12.0;

  /// A book cover is taller than it is wide — 3:2 is the shape most of this
  /// catalogue's covers actually are. Derived from the column width rather
  /// than fixed at 170, which is what made the cell overflow on a narrow
  /// phone: the cover kept its height while the column got thinner, so there
  /// was no room left for the two lines of text under it (reported on an
  /// Honor 600, where the author line was sliced in half by the next row).
  static const _coverAspect = 1.5;
  static const _gapUnderCover = 6.0;
  static const _titleFontSize = 12.0;
  static const _authorFontSize = 11.0;

  /// Room for one line of title and one of author, at whatever text size the
  /// phone is set to. 1.6 is a deliberate over-estimate of the font's line
  /// box — the real factor depends on the font the platform resolves, and
  /// 1.4 turned out to be under it by a fraction of a pixel. A few spare
  /// pixels per cell cost nothing; being short by one clips the author's
  /// name on every card.
  static double _labelsHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _gapUnderCover + scaler.scale(_titleFontSize) * 1.6 + scaler.scale(_authorFontSize) * 1.6;
  }

  final List<LibraryBook> books;
  final EdgeInsets padding;
  final bool loadingMore;

  /// Owned by [SearchScreen] rather than by this widget, because the
  /// infinite-scroll trigger has to read the position *outside* a scroll
  /// notification — see `_maybeLoadMore`.
  final ScrollController? controller;

  const SearchResultGrid({super.key, required this.books, required this.padding, required this.loadingMore, this.controller});

  @override
  Widget build(BuildContext context) {
    // The width one column actually gets, so the cell's height can be built
    // from its contents instead of a ratio that only happens to fit on the
    // screen it was tuned on.
    final columnWidth = (MediaQuery.sizeOf(context).width - padding.horizontal - _crossAxisSpacing * (_crossAxisCount - 1)) / _crossAxisCount;
    final coverHeight = columnWidth * _coverAspect;
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: 0,
              crossAxisSpacing: _crossAxisSpacing,
              mainAxisExtent: coverHeight + 20 + _labelsHeight(context),
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
                child: CatalogBookCard(book: books[i], heroTag: AppHeroTags.catalogBookCover(books[i].id), width: double.infinity, coverHeight: coverHeight, margin: EdgeInsets.zero),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
