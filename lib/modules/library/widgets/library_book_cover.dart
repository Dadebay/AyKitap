import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../book_detail/catalog_book_detail_screen.dart';

/// A shelf cover for a real [LibraryBook] (`GET /books/all`, or a locally
/// saved [DownloadedBooksStore] entry) — tapping opens
/// [CatalogBookDetailScreen].
class LibraryBookCover extends StatelessWidget {
  final LibraryBook book;
  final bool showProgress;
  const LibraryBookCover({super.key, required this.book, this.showProgress = false});

  /// The backend hasn't sent a non-null sample yet to confirm its scale —
  /// this treats anything already ≤ 1 as a 0–1 fraction and anything above
  /// as a 0–100 percentage, so either shape reads correctly.
  static double? _normalize(double? raw) {
    if (raw == null) return null;
    return raw > 1 ? (raw / 100).clamp(0, 1) : raw.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final progress = showProgress ? _normalize(book.progress) : null;
    final image = book.image;
    return GestureDetector(
      onTap: () => context.push(CatalogBookDetailScreen(bookId: book.id)),
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: image != null && image.isNotEmpty
                    ? NetworkCoverImage(url: ApiConfig.resolveImageUrl(image), placeholder: (_) => _CoverPlaceholder())
                    : _CoverPlaceholder(),
              ),
            ),
            if (progress != null)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(
                  child: Text(
                    '${(progress * 100).round()}%',
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

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedBook02, color: AppColors.grey3, size: 22)),
    );
  }
}

/// White, shadowed circular badge pinned to a shelf cover's corner.
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
