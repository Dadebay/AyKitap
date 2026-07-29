import 'package:flutter/material.dart';
import '../../core/models/library_book.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import 'widgets/catalog_book_card.dart';

/// "Ählisini gör" / "see more" destination for one real [Collection]'s full
/// book list — the real-catalogue counterpart to `CollectionBooksScreen`
/// (mock `Book`), reusing the same [CatalogBookCard] every other real-book
/// list in the app uses (Home's rows, [CatalogAuthorDetailScreen]) rather
/// than a one-off card design just for this grid.
class CatalogCollectionBooksScreen extends StatelessWidget {
  final String title;
  final List<LibraryBook> books;
  const CatalogCollectionBooksScreen({super.key, required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          itemCount: books.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.5,
          ),
          itemBuilder: (context, i) => CatalogBookCard(book: books[i], width: double.infinity, coverHeight: 170, margin: EdgeInsets.zero),
        ),
      ),
    );
  }
}
