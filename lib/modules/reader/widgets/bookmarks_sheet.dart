import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// TZ §12.1 — the 🔖 button's sheet: this book's bookmarks, with an action at
/// the top to mark/unmark the page you're on. Tapping a row jumps there.
/// Every book's marks also show up together in the profile.
class BookmarksSheet extends StatelessWidget {
  const BookmarksSheet({super.key});

  static const _accent = Color(0xFFE8712C);
  static const _panel = Color(0xFF1E1E2E);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        final marks = provider.bookmarks;
        final onThisPage = provider.isCurrentPageBookmarked;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: const BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ReaderStrings.bookmarksTitle,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),

              // Mark / unmark the page currently on screen.
              GestureDetector(
                onTap: () => provider.toggleBookmark(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: onThisPage ? Colors.white10 : _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        onThisPage ? Icons.bookmark_remove : Icons.bookmark_add,
                        color: onThisPage ? Colors.white70 : Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        onThisPage ? ReaderStrings.removeCurrentPage : ReaderStrings.addCurrentPage,
                        style: TextStyle(
                          color: onThisPage ? Colors.white70 : Colors.white,
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
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: marks.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, i) {
                      final b = marks[i];
                      final percent = (b.progress * 100).round();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark, color: _accent, size: 20),
                        title: Text(
                          b.chapterTitle.isNotEmpty ? b.chapterTitle : ReaderStrings.bookmarkProgress(percent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: b.chapterTitle.isNotEmpty
                            ? Text(
                                ReaderStrings.bookmarkProgress(percent),
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
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
