import 'package:flutter/material.dart';
import '../../../core/models/author_detail.dart';
import '../../home/widgets/catalog_author_card.dart';

/// [SearchScreen]'s "Ýazar" mode results — a two-column grid of
/// [CatalogAuthorCard]s, mirroring [SearchResultGrid]'s book grid so both
/// search modes read as the same kind of results page.
class AuthorResultGrid extends StatelessWidget {
  final List<AuthorSearchResult> authors;
  final EdgeInsets padding;

  const AuthorResultGrid(
      {super.key, required this.authors, required this.padding});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 14,
        // The 2:3 photo plus up to two lines of name and the badge row
        // below it comes out close to 1:2 (width:height) at a typical
        // two-column cell width — see [CatalogAuthorCard].
        childAspectRatio: 0.53,
      ),
      itemCount: authors.length,
      itemBuilder: (_, i) => CatalogAuthorCard(
        authorId: authors[i].id,
        name: authors[i].name,
        image: authors[i].image,
        bookCount: authors[i].bookCount,
        width: double.infinity,
      ),
    );
  }
}
