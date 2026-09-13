import 'package:flutter/material.dart';
import '../../../core/models/author_detail.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/catalog_author_avatar.dart';

/// [SearchScreen]'s "Awtor" mode results — a three-column grid of
/// [CatalogAuthorAvatar]s, mirroring [SearchResultGrid]'s book grid so both
/// search modes read as the same kind of results page, infinite scroll
/// included: a [CustomScrollView] rather than a plain [GridView.builder] so
/// the next-page spinner can sit as its own sliver under the grid instead of
/// needing an off-by-one extra cell for it.
class AuthorResultGrid extends StatelessWidget {
  static const _crossAxisCount = 3;

  final List<AuthorSearchResult> authors;
  final EdgeInsets padding;
  final bool loadingMore;

  const AuthorResultGrid({
    super.key,
    required this.authors,
    required this.padding,
    this.loadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              // A fixed pixel height instead of childAspectRatio: the card's
              // content height (padding + 88-diameter photo + up to two lines
              // of name) is constant regardless of column count, but an
              // aspect-ratio-derived height shrinks along with cell *width* as
              // more columns are added — which is what overflowed at 3
              // columns. Matches the Home author rail's row height — see
              // [CatalogAuthorAvatar].
              mainAxisExtent: 160,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => CatalogAuthorAvatar(
                authorId: authors[i].id,
                name: authors[i].name,
                image: authors[i].image,
                width: double.infinity,
              ),
              childCount: authors.length,
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
