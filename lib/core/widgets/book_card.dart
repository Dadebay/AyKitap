import 'package:flutter/material.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';
import 'book_cover.dart';

/// A cover + title + author list cell — the shape reused across Home's
/// horizontal shelves and Book Detail's "more from this author" strip.
/// Takes its own [onTap] so callers don't need to wrap it in a
/// `GestureDetector` themselves.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.width = 100,
    this.coverHeight = 155,
    this.margin = const EdgeInsets.only(left: 6, right: 10),
  });

  final Book book;
  final VoidCallback? onTap;
  final double width;
  final double coverHeight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
              imagePath: book.coverImage,
              width: double.infinity,
              height: coverHeight),
          const SizedBox(height: 6),
          Text(book.title,
              style: TextStyle(
                  color: AppColors.grey1,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(book.author.name,
              style: TextStyle(color: AppColors.grey2, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
