import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/book_detail_strings.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/services/book_api_service.dart';
import '../../../core/services/favorites_sync_service.dart';
import '../../../core/services/finished_books_sync_service.dart';
import '../../../core/services/reading_books_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_cover_image.dart';

/// What a long-press "poz" does on each [LibraryScreen] shelf. Every shelf
/// is a different *relationship* to the same catalogue book — progress, a
/// purchase, a like — so removing one from a shelf means calling a
/// different endpoint, never deleting the book itself.
///
/// [reading] and [finished] deliberately share one call: both shelves are
/// views of a single progress record (`my_books` vs `my_books&finished`),
/// so `DELETE /books/:id/progress` clears either of them. They stay
/// separate cases only so the confirm dialog can name the right shelf.
enum ShelfRemoval { reading, finished, purchased, favorite }

extension ShelfRemovalActions on ShelfRemoval {
  String confirmMessage(String bookName) => switch (this) {
        ShelfRemoval.reading => LibraryStrings.deleteReadingConfirm(bookName),
        ShelfRemoval.finished => LibraryStrings.deleteFinishedConfirm(bookName),
        ShelfRemoval.purchased => LibraryStrings.deletePurchasedConfirm(bookName),
        ShelfRemoval.favorite => LibraryStrings.deleteFavoriteConfirm(bookName),
      };

  /// Runs the backend call and mirrors it into the offline caches that
  /// shadow the same shelf, so the book doesn't reappear from disk on the
  /// next cold start (or keep opening in airplane mode, for a purchase).
  /// Throws [ApiException] — the caller surfaces it and keeps the cover.
  Future<void> apply(int bookId) async {
    switch (this) {
      case ShelfRemoval.reading:
      case ShelfRemoval.finished:
        await BookApiService.deleteProgress(bookId);
        await ReadingBooksStore.instance.remove(bookId);
      case ShelfRemoval.purchased:
        await BookApiService.removeBoughtBook(bookId);
        await BookAccessService.instance.removePurchased(bookId);
      case ShelfRemoval.favorite:
        await BookApiService.unlikeBook('$bookId');
    }
  }

  /// Pings the shelves that show the same state from elsewhere in the app,
  /// so they re-fetch instead of holding a stale (kept-alive) list — e.g. a
  /// book deleted from "Okaýanlarym" also has to leave "Okap gutaranlarym".
  void notifyShelvesChanged() {
    switch (this) {
      case ShelfRemoval.reading:
      case ShelfRemoval.finished:
        FinishedBooksSyncService.instance.notifyChanged();
      case ShelfRemoval.purchased:
        break;
      case ShelfRemoval.favorite:
        FavoritesSyncService.instance.notifyChanged();
    }
  }
}

/// The one delete dialog every shelf shows on long-press. Built in the same
/// language as [StreakRewardDialog] — a card with a badged illustration on
/// top and full-width actions — rather than the flat [AlertDialog] the
/// download/purchase confirmations used, so a destructive step reads as a
/// deliberate moment instead of a system alert.
///
/// [coverUrl] shows the actual book being deleted (with the trash badge
/// clipped onto its corner); imported files have no artwork, so those fall
/// back to a plain tinted icon circle.
///
/// [extraLabel] adds one non-destructive way out beside "cancel" — the
/// downloaded shelf's "save the file first", which used to live in a bottom
/// sheet in front of this dialog.
Future<ShelfDeleteChoice> showShelfDeleteDialog(
  BuildContext context, {
  required String message,
  String? title,
  String? coverUrl,
  String? extraLabel,
}) async {
  final choice = await showDialog<ShelfDeleteChoice>(
    context: context,
    builder: (context) => _ShelfDeleteDialog(
      message: message,
      title: title,
      coverUrl: coverUrl,
      extraLabel: extraLabel,
    ),
  );
  return choice ?? ShelfDeleteChoice.cancel;
}

/// How the delete dialog was dismissed. [extra] only ever comes back when
/// the caller passed an `extraLabel`.
enum ShelfDeleteChoice { cancel, delete, extra }

class _ShelfDeleteDialog extends StatelessWidget {
  const _ShelfDeleteDialog({
    required this.message,
    this.title,
    this.coverUrl,
    this.extraLabel,
  });

  final String message;
  final String? title;
  final String? coverUrl;
  final String? extraLabel;

  static const _danger = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Illustration(coverUrl: coverUrl),
            const SizedBox(height: 18),
            Text(title ?? LibraryStrings.deleteTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.grey1, fontSize: 13.5, height: 1.45)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, ShelfDeleteChoice.delete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(LibraryStrings.delete,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (extraLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                // Outlined, not filled: it's a real alternative to deleting
                // (keep a copy of the file first), but the card should still
                // read as one decision, not two competing buttons.
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, ShelfDeleteChoice.extra),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(extraLabel!,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 44,
              // The safe way out is the plainest thing on the card: the
              // destructive button is the only filled one, so a half-read
              // dialog can't be dismissed *into* the delete.
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(BookDetailStrings.cancel,
                    style: TextStyle(
                        color: AppColors.grey2,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cover being deleted, with a trash badge on its corner — or a tinted
/// icon circle when there's no artwork to show.
class _Illustration extends StatelessWidget {
  const _Illustration({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final url = coverUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
            color: _ShelfDeleteDialog._danger.withValues(alpha: 0.14),
            shape: BoxShape.circle),
        child: const Center(
          child: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: _ShelfDeleteDialog._danger,
              size: 32),
        ),
      );
    }
    return SizedBox(
      width: 72,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: NetworkCoverImage(
                url: url,
                placeholder: (_) => Container(color: AppColors.bg),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _ShelfDeleteDialog._danger,
                shape: BoxShape.circle,
                // Reads as a badge cut into the cover rather than a sticker
                // floating over it, whichever theme the card is painted in.
                border: Border.all(color: AppColors.card, width: 3),
              ),
              child: const Center(
                child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: Colors.white,
                    size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
