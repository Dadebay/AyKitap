import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sakura_epub/sakura_epub.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// TZ §12.3 — the "Mazmun" sheet: a header (cover, title, reading position and
/// a progress bar) over the book's table of contents. The TOC is a tree
/// (part → chapter → sub-heading), so it's flattened into indented rows here;
/// the chapter currently on screen is highlighted as a filled block.
class ChapterListSheet extends StatelessWidget {
  final String bookTitle;
  final String? coverImage;
  final int? bookPages;

  const ChapterListSheet({
    super.key,
    required this.bookTitle,
    this.coverImage,
    this.bookPages,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        final entries = _flatten(provider.chapters);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header: cover, title, reading position, close ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Cover(coverImage: coverImage),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _positionLabel(provider.progress),
                              style: TextStyle(color: AppColors.grey2, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: AppColors.grey2, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Reading-progress bar — the accent line under the header.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: provider.progress.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(ReaderStrings.noChaptersFound, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => Divider(color: AppColors.border, height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (_, i) => _ChapterTile(
                          entry: entries[i],
                          current: provider.isChapterCurrent(entries[i].chapter),
                          onTap: () {
                            provider.goToChapter(entries[i].chapter);
                            Navigator.pop(context);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// "Sahypa X / Y" when the catalogue gives a page count (the page is
  /// estimated from the 0–1 progress); otherwise the plain percentage.
  String _positionLabel(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (bookPages != null && bookPages! > 0) {
      final page = (p * bookPages!).round().clamp(1, bookPages!);
      return ReaderStrings.pageOfPages(page, bookPages!);
    }
    return ReaderStrings.bookmarkProgress((p * 100).round());
  }

  /// Depth-first flatten of the TOC tree into rows carrying their nesting
  /// depth, so the list can indent children under their parent.
  static List<_TocEntry> _flatten(List<EpubChapter> chapters, [int depth = 0]) {
    final out = <_TocEntry>[];
    for (final c in chapters) {
      out.add(_TocEntry(chapter: c, depth: depth));
      if (c.subitems.isNotEmpty) out.addAll(_flatten(c.subitems, depth + 1));
    }
    return out;
  }
}

class _Cover extends StatelessWidget {
  final String? coverImage;
  const _Cover({required this.coverImage});

  @override
  Widget build(BuildContext context) {
    const w = 46.0, h = 62.0;
    if (coverImage == null || coverImage!.isEmpty) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.menu_book_rounded, color: AppColors.grey3, size: 22),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        coverImage!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: w,
          height: h,
          color: AppColors.card,
          child: Icon(Icons.menu_book_rounded, color: AppColors.grey3, size: 22),
        ),
      ),
    );
  }
}

class _TocEntry {
  final EpubChapter chapter;
  final int depth;
  const _TocEntry({required this.chapter, required this.depth});
}

class _ChapterTile extends StatelessWidget {
  final _TocEntry entry;
  final bool current;
  final VoidCallback onTap;

  const _ChapterTile({required this.entry, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTop = entry.depth == 0;
    final title = entry.chapter.title.trim().isNotEmpty ? entry.chapter.title.trim() : entry.chapter.href;

    return Material(
      color: current ? AppColors.card : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20 + entry.depth * 16, 15, 20, 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: current
                        ? AppColors.primary
                        : isTop
                            ? AppColors.white
                            : AppColors.grey1,
                    fontSize: isTop ? 14 : 13.5,
                    fontWeight: current || isTop ? FontWeight.w700 : FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),
              if (current) ...[
                const SizedBox(width: 10),
                HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.primary, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
