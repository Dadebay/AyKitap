import 'package:flutter/material.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/models/book_detail.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/stagger_fade_in.dart';
import 'genre_tag.dart';

/// The genres wrap and the expandable synopsis — controlled from outside
/// ([expanded]/[onToggleExpanded]) since [CatalogBookDetailScreen] owns
/// that bit of UI state.
///
/// Genres and the synopsis get their own [StaggerFadeIn] entrance apiece,
/// continuing the stagger sequence from [startIndex] — see
/// [CatalogDetailHeaderInfo]'s doc comment for why the numbering is passed
/// in rather than each widget assuming it owns index 0.
class CatalogDetailDescription extends StatelessWidget {
  final BookDetail book;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<BookDetailGenre> onTapGenre;
  final int startIndex;

  const CatalogDetailDescription({
    super.key,
    required this.book,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onTapGenre,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.genres.isNotEmpty) ...[
          const SizedBox(height: 24),
          StaggerFadeIn(
            index: startIndex,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            ),
          ),
        ],
        if (book.description != null && book.description!.isNotEmpty) ...[
          const SizedBox(height: 24),
          StaggerFadeIn(
            index: startIndex + (book.genres.isNotEmpty ? 1 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  overflow:
                      expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.grey1, fontSize: 13.5, height: 1.5),
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
            ),
          ),
        ],
      ],
    );
  }

  /// Mirrors [CatalogDetailHeaderInfo.stepCount] — how many stagger steps
  /// this widget consumes, so the CTA section below can continue the
  /// sequence without hardcoding this widget's internal block count.
  static int stepCount(BookDetail book) =>
      (book.genres.isNotEmpty ? 1 : 0) +
      (book.description != null && book.description!.isNotEmpty ? 1 : 0);
}
