import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_bookmark_strings.dart';
import '../../../core/models/bookmark.dart';
import '../../../core/theme/app_colors.dart';

/// The PDF reader's 🔖 sheet — the counterpart of [BookmarksSheet], same layout
/// and same behaviour: mark or unmark the page you're on at the top, this
/// book's marks below, tap a row to jump there.
///
/// It takes its data as plain values rather than reading [ReaderProvider],
/// because that provider drives the EPUB engine and knows nothing about a PDF;
/// the PDF screen owns this state itself and passes it down.
class PdfBookmarksSheet extends StatelessWidget {
  final List<Bookmark> bookmarks;

  /// Whether the page currently on screen is already marked.
  final bool isCurrentPageBookmarked;

  final VoidCallback onToggleCurrent;
  final ValueChanged<Bookmark> onJump;
  final ValueChanged<String> onRemove;

  const PdfBookmarksSheet({
    super.key,
    required this.bookmarks,
    required this.isCurrentPageBookmarked,
    required this.onToggleCurrent,
    required this.onJump,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ReaderBookmarkStrings.bookmarksTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          // Mark / unmark the page currently on screen.
          GestureDetector(
            onTap: onToggleCurrent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isCurrentPageBookmarked
                    ? AppColors.card
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: isCurrentPageBookmarked
                        ? HugeIcons.strokeRoundedBookmarkRemove02
                        : HugeIcons.strokeRoundedBookmarkAdd02,
                    color: isCurrentPageBookmarked
                        ? AppColors.grey2
                        : Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCurrentPageBookmarked
                        ? ReaderBookmarkStrings.removeCurrentPage
                        : ReaderBookmarkStrings.addCurrentPage,
                    style: TextStyle(
                      color: isCurrentPageBookmarked
                          ? AppColors.grey2
                          : Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedBookmark02,
                        color: AppColors.grey3,
                        size: 34),
                    const SizedBox(height: 10),
                    Text(ReaderBookmarkStrings.bookmarksEmpty,
                        style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bookmarks.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.border, height: 1),
                itemBuilder: (_, i) {
                  final b = bookmarks[i];
                  final percent = (b.progress * 100).round();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedBookmark01,
                        color: AppColors.primary,
                        size: 20),
                    // chapterTitle carries the "Sahypa 12 / 340" label the PDF
                    // screen stored when the mark was made.
                    title: Text(
                      b.chapterTitle.isNotEmpty
                          ? b.chapterTitle
                          : ReaderBookmarkStrings.bookmarkProgress(percent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      ReaderBookmarkStrings.bookmarkProgress(percent),
                      style: TextStyle(color: AppColors.grey2, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          color: AppColors.grey2,
                          size: 20),
                      onPressed: () => onRemove(b.id),
                    ),
                    onTap: () {
                      onJump(b);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
