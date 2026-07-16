import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../navigation/app_navigator.dart';
import '../localization/strings/series_strings.dart';
import '../../modules/popular/collection_books_screen.dart';

/// A large image card for a book series — cover photo with a frosted-glass
/// panel over the bottom edge and the series title / book count on top of
/// it. Reused by [HomeScreen]'s horizontal row and the full
/// `AllSeriesScreen` list, so it just fills whatever box the caller sizes
/// it to.
class SeriesCard extends StatelessWidget {
  final BookSeries series;
  const SeriesCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(CollectionBooksScreen(title: series.title, books: series.books)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(series.coverImage, fit: BoxFit.cover),
            // Frosted glass strip pinned to the bottom edge — the art above
            // it stays untouched and sharp, only the text panel itself is
            // blurred and tinted so the title/count stay legible.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    color: Colors.black.withValues(alpha: 0.32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          series.title,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          SeriesStrings.bookCount(series.bookCount),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
