import 'package:flutter/material.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/models/library_book.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/catalog_book_card.dart';
import 'author_books_sort.dart';
import 'author_books_sort_button.dart';
import 'author_no_books_state.dart';

/// "Ähli kitaplar" heading + sort button + 3-column grid, or the empty
/// state when the author has no books — the bottom section of
/// [CatalogAuthorDetailScreen]'s content sheet.
class AuthorBooksGridSection extends StatelessWidget {
  final List<LibraryBook> sortedBooks;
  final AuthorBooksSort? sort;
  final ValueChanged<AuthorBooksSort?> onSortChanged;

  const AuthorBooksGridSection(
      {super.key,
      required this.sortedBooks,
      required this.sort,
      required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    if (sortedBooks.isEmpty) return const AuthorNoBooksState();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AuthorStrings.allBooks,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            AuthorBooksSortButton(sort: sort, onChanged: onSortChanged),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedBooks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.50,
          ),
          itemBuilder: (context, i) => CatalogBookCard(
              book: sortedBooks[i],
              width: double.infinity,
              coverHeight: 170,
              margin: EdgeInsets.zero),
        ),
      ],
    );
  }
}
