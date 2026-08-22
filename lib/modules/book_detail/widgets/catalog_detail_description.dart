import 'package:flutter/material.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/theme/app_colors.dart';
import 'genre_tag.dart';

/// The genres wrap and the expandable synopsis — controlled from outside
/// ([expanded]/[onToggleExpanded]) since [CatalogBookDetailScreen] owns
/// that bit of UI state.
class CatalogDetailDescription extends StatelessWidget {
  final BookDetail book;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<BookDetailGenre> onTapGenre;

  const CatalogDetailDescription({
    super.key,
    required this.book,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onTapGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.genres.isNotEmpty) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(BookDetailStrings.genres,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.genres
                  .map((g) =>
                      GenreTag(label: g.name, onTap: () => onTapGenre(g)))
                  .toList(),
            ),
          ),
        ],
        if (book.description != null && book.description!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(BookDetailStrings.aboutBook,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Text(
            book.description!,
            maxLines: expanded ? null : 5,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style:
                TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onToggleExpanded,
              child: Text(
                expanded
                    ? BookDetailStrings.showLess
                    : BookDetailStrings.readFull,
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
