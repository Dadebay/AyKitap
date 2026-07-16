import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/theme/app_colors.dart';
import '../../book_detail/book_detail_screen.dart';

class ShelfBookCover extends StatelessWidget {
  final Book book;
  final bool heart;
  final bool downloaded;
  final double? progress;
  const ShelfBookCover({super.key, required this.book, this.heart = false, this.downloaded = false, this.progress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(BookDetailScreen(book: book)),
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(book.coverImage, fit: BoxFit.cover),
              ),
            ),
            if (heart)
              const Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(child: HugeIcon(icon: HugeIcons.strokeRoundedFavourite, color: Colors.redAccent, size: 12)),
              ),
            if (downloaded)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(child: HugeIcon(icon: HugeIcons.strokeRoundedDownload01, color: AppColors.primary, size: 12)),
              ),
            if (progress != null)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(
                  child: Text(
                    '${(progress! * 100).round()}%',
                    style: const TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// White, shadowed circular badge pinned to a shelf cover's corner — used
/// for the favourite heart, the downloaded checkmark, and the reading %.
class _CornerBadge extends StatelessWidget {
  final Widget child;
  const _CornerBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: child,
    );
  }
}
