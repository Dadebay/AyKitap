import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/library_book.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';
import '../../book_detail/catalog_book_detail_screen.dart';

/// A shelf cover for a real [LibraryBook] (`GET /books/all`, or a locally
/// saved [DownloadedBooksStore] entry) — tapping opens
/// [CatalogBookDetailScreen].
class LibraryBookCover extends StatelessWidget {
  final LibraryBook book;
  final bool showProgress;
  final bool canRemoveFromPurchased;
  final VoidCallback? onPurchasedBookRemoved;

  /// Draws a lock over the cover when the book can't currently be opened —
  /// only meaningful on the downloaded shelf, where a file can outlive the
  /// subscription that granted access to it ([BookAccessService.canRead]).
  final bool showLockWhenNoAccess;

  /// Long-press action, used by the downloaded shelf for "Ýüklemäni poz".
  final VoidCallback? onLongPress;

  /// Replaces the default "open the detail page" tap. The downloaded shelf
  /// uses it to open the local file straight away, which is what makes that
  /// shelf work with no connection.
  final VoidCallback? onTap;

  const LibraryBookCover({
    super.key,
    required this.book,
    this.showProgress = false,
    this.canRemoveFromPurchased = false,
    this.onPurchasedBookRemoved,
    this.showLockWhenNoAccess = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = showProgress ? book.progressFraction : null;
    final image = book.image;
    final locked = showLockWhenNoAccess && !BookAccessService.instance.canRead(book.id);
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap ??
          () async {
            final removed = await context.push<bool>(
              CatalogBookDetailScreen(
                bookId: book.id,
                canRemoveFromPurchased: canRemoveFromPurchased,
              ),
            );
            if (removed == true) onPurchasedBookRemoved?.call();
          },
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: image != null && image.isNotEmpty
                    ? NetworkCoverImage(
                        url: ApiConfig.resolveImageUrl(image),
                        placeholder: (_) => _CoverPlaceholder())
                    : _CoverPlaceholder(),
              ),
            ),
            if (locked)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const HugeIcon(icon: HugeIcons.strokeRoundedSquareLock02, color: Colors.white, size: 22),
                  ),
                ),
              ),
            if (progress != null)
              Positioned(
                top: 4,
                right: 4,
                child: _CornerBadge(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 8,
                        fontWeight: FontWeight.w800),
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
      child: Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedBook02,
              color: AppColors.grey3,
              size: 22)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: child,
    );
  }
}
