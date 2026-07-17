import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';

/// TZ §12.1 — the 🔖 button's sheet: this book's bookmarks, with an action at
/// the top to mark/unmark the page you're on. Tapping a row jumps there.
/// Every book's marks also show up together in the profile.
class BookmarksSheet extends StatelessWidget {
  const BookmarksSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        final marks = provider.bookmarks;
        final onThisPage = provider.isCurrentPageBookmarked;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ReaderStrings.bookmarksTitle,
                style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),

              // Mark / unmark the page currently on screen.
              GestureDetector(
                onTap: () => provider.toggleBookmark(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: onThisPage ? AppColors.card : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        onThisPage ? Icons.bookmark_remove : Icons.bookmark_add,
                        color: onThisPage ? AppColors.grey2 : Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        onThisPage ? ReaderStrings.removeCurrentPage : ReaderStrings.addCurrentPage,
                        style: TextStyle(
                          color: onThisPage ? AppColors.grey2 : Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (marks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      ReaderStrings.bookmarksEmpty,
                      style: TextStyle(color: AppColors.grey2, fontSize: 14),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: marks.length,
                    separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1),
                    itemBuilder: (_, i) {
                      final b = marks[i];
                      final percent = (b.progress * 100).round();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.bookmark, color: AppColors.primary, size: 20),
                        title: Text(
                          b.chapterTitle.isNotEmpty ? b.chapterTitle : ReaderStrings.bookmarkProgress(percent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: b.chapterTitle.isNotEmpty
                            ? Text(
                                ReaderStrings.bookmarkProgress(percent),
                                style: TextStyle(color: AppColors.grey2, fontSize: 12),
                              )
                            : null,
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.grey2, size: 20),
                          onPressed: () => provider.removeBookmark(b.id),
                        ),
                        onTap: () {
                          provider.goToBookmark(b.cfi);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
