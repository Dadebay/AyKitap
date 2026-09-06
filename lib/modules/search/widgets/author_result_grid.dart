import 'package:flutter/material.dart';
import '../../../core/models/author_detail.dart';
import '../../home/widgets/catalog_author_avatar.dart';

/// [SearchScreen]'s "Awtor" mode results — a three-column grid of
/// [CatalogAuthorAvatar]s, mirroring [SearchResultGrid]'s book grid so both
/// search modes read as the same kind of results page.
class AuthorResultGrid extends StatelessWidget {
  final List<AuthorSearchResult> authors;
  final EdgeInsets padding;

  const AuthorResultGrid({super.key, required this.authors, required this.padding});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        // A fixed pixel height instead of childAspectRatio: the card's
        // content height (padding + 88-diameter photo + up to two lines of
        // name) is constant regardless of column count, but an
        // aspect-ratio-derived height shrinks along with cell *width* as
        // more columns are added — which is what overflowed at 3 columns.
        // Matches the Home author rail's row height — see
        // [CatalogAuthorAvatar].
        mainAxisExtent: 160,
      ),
      itemCount: authors.length,
      itemBuilder: (_, i) => CatalogAuthorAvatar(
        authorId: authors[i].id,
        name: authors[i].name,
        image: authors[i].image,
        width: double.infinity,
      ),
    );
  }
}
