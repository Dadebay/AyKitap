import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/book.dart';
import '../../../core/services/purchased_books_store.dart';
import '../../../core/localization/strings/library_strings.dart';
import 'library_empty_state.dart';
import 'shelf_book_cover.dart';
import 'shelf_grid.dart';

class ReadingTab extends StatelessWidget {
  final List<Book> books;
  const ReadingTab({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return LibraryEmptyState(label: LibraryStrings.emptyReading);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => ShelfBookCover(book: books[i], progress: ((i + 1) * 17) % 100 / 100),
      ),
    );
  }
}

class DownloadedTab extends StatelessWidget {
  final List<Book> books;
  const DownloadedTab({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return LibraryEmptyState(label: LibraryStrings.emptyDownloaded, sub: LibraryStrings.emptyDownloadedSub);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => ShelfBookCover(book: books[i], downloaded: true),
      ),
    );
  }
}

/// "Satyn Alinanlar" — real per-book purchases from [PurchasedBooksStore],
/// unlike the other tabs here which still show mock catalogue slices.
class PurchasedTab extends StatefulWidget {
  const PurchasedTab({super.key});

  @override
  State<PurchasedTab> createState() => _PurchasedTabState();
}

class _PurchasedTabState extends State<PurchasedTab> {
  @override
  void initState() {
    super.initState();
    PurchasedBooksStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<PurchasedBooksStore>().purchasedBooks;
    return SimpleBookListTab(books: books, emptyLabel: LibraryStrings.emptyPurchased);
  }
}

class SimpleBookListTab extends StatelessWidget {
  final List<Book> books;
  final String emptyLabel;
  final bool heart;
  const SimpleBookListTab({super.key, required this.books, required this.emptyLabel, this.heart = false});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return LibraryEmptyState(label: emptyLabel);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: ShelfGrid(
        itemCount: books.length,
        itemBuilder: (context, i) => ShelfBookCover(book: books[i], heart: heart),
      ),
    );
  }
}
