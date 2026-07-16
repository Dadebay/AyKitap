import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/models/bookmark.dart';
import '../../core/services/bookmarks_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/localization/strings/profile_strings.dart';

/// "Ähli bellikleri gör" — every book's bookmarks in one place (TZ §12.1).
/// The reader shows only the open book's marks; this is the cross-book view,
/// grouped by book so a reader with several books on the go can still tell
/// them apart.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    BookmarksStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<BookmarksStore>().all;

    // Group by book, keeping the newest-first order of `all` for the groups
    // themselves so recently-used books float to the top.
    final grouped = <int, List<Bookmark>>{};
    for (final b in all) {
      grouped.putIfAbsent(b.bookId, () => []).add(b);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(size: 20),
        title: Text(
          ProfileStrings.bookmarksTitle,
          style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: all.isEmpty ? _buildEmpty() : _buildList(grouped),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedBookmark01, color: AppColors.grey3, size: 44),
            const SizedBox(height: 16),
            Text(
              ProfileStrings.bookmarksEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Map<int, List<Bookmark>> grouped) {
    final entries = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final marks = entries[i].value;
        // Within a book, read top-to-bottom like the book does.
        final ordered = [...marks]..sort((a, b) => a.progress.compareTo(b.progress));
        final title = ordered.first.bookTitle;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                title.isNotEmpty ? title : '—',
                style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  for (var j = 0; j < ordered.length; j++) ...[
                    if (j > 0) Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 48),
                    _BookmarkRow(bookmark: ordered[j]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  final Bookmark bookmark;
  const _BookmarkRow({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final percent = (bookmark.progress * 100).round();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: HugeIcon(icon: HugeIcons.strokeRoundedBookmark01, color: AppColors.primary, size: 20),
      title: Text(
        bookmark.chapterTitle.isNotEmpty ? bookmark.chapterTitle : '$percent%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.grey1, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: bookmark.chapterTitle.isNotEmpty
          ? Text('$percent%', style: TextStyle(color: AppColors.grey2, fontSize: 12))
          : null,
      trailing: IconButton(
        icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: AppColors.grey3, size: 18),
        onPressed: () => BookmarksStore.instance.remove(bookmark.id),
      ),
    );
  }
}
