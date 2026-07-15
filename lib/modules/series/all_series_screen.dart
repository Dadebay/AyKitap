import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../popular/collection_books_screen.dart';
import '../../core/localization/strings/series_strings.dart';

/// A large image card for a book series — cover photo with a dark bottom
/// scrim and the series title / book count overlaid. Reused by the
/// HomeScreen horizontal row and the full [AllSeriesScreen] list, so it
/// just fills whatever box the caller sizes it to.
class SeriesCard extends StatelessWidget {
  final BookSeries series;
  const SeriesCard({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CollectionBooksScreen(title: series.title, books: series.books)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(series.coverImage, fit: BoxFit.cover),
            // Scrim so the white text stays legible over the art — starts
            // fading in from a third of the way down and is nearly opaque
            // by the bottom, so the title/count read clearly on any cover.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.35, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    series.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SeriesStrings.bookCount(series.bookCount),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full catalogue behind the "Ählisi" button — every series stacked as big
/// cards, one per row.
class AllSeriesScreen extends StatelessWidget {
  const AllSeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final series = MockData.series;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(SeriesStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: series.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => SizedBox(
          height: 200,
          child: SeriesCard(series: series[i]),
        ),
      ),
    );
  }
}
