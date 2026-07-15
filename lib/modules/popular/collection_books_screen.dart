import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../book_detail/book_detail_screen.dart';
import '../../core/localization/strings/popular_strings.dart';

/// Book list behind a Kolleksiýalar "uly kart" (big card) — e.g. tapping
/// "New York Times Bestsellers" opens its 50 books here, switchable
/// between a list and a grid the same way PopularBooksScreen is.
class CollectionBooksScreen extends StatefulWidget {
  final String title;
  final List<Book> books;
  const CollectionBooksScreen({super.key, required this.title, required this.books});

  @override
  State<CollectionBooksScreen> createState() => _CollectionBooksScreenState();
}

class _CollectionBooksScreenState extends State<CollectionBooksScreen> {
  bool _isGrid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: _isGrid ? HugeIcons.strokeRoundedListView : HugeIcons.strokeRoundedGridView,
              color: AppColors.grey1,
              size: 20,
            ),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isGrid ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CollectionListTile(book: widget.books[i]),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: 0.5,
      ),
      itemCount: widget.books.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: widget.books[i]))),
        child: _CollectionGridCard(book: widget.books[i]),
      ),
    );
  }
}

class _CollectionListTile extends StatelessWidget {
  final Book book;
  const _CollectionListTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: book))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 74,
              child: Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(book.coverImage, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(book.isFree ? PopularStrings.free : PopularStrings.priceManat(book.priceManat), style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionGridCard extends StatelessWidget {
  final Book book;
  const _CollectionGridCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(book.coverImage, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(book.title, style: TextStyle(color: AppColors.grey1, fontSize: 11.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(book.author.name, style: TextStyle(color: AppColors.grey2, fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
