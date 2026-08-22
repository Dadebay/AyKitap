import 'package:flutter/material.dart';
import '../../../core/models/library_book.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/catalog_book_card.dart';

/// Shared by [SearchScreen]'s search-results and discover grids — three
/// columns of covers, plus a spinner row at the bottom while the next page
/// is in flight. A [CustomScrollView] rather than a plain [GridView.builder]
/// so that spinner can sit as its own sliver below the grid instead of
/// needing an off-by-one extra grid cell for it.
class SearchResultGrid extends StatelessWidget {
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
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => CatalogBookCard(
                  book: books[i],
                  width: double.infinity,
                  coverHeight: 170,
                  margin: EdgeInsets.zero),
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
