import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sakura_epub/sakura_epub.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// One row of [ChapterListSheet]'s depth-first-flattened TOC, carrying its
/// nesting depth so the list can indent children under their parent.
class TocEntry {
  final EpubChapter chapter;
  final int depth;
  const TocEntry({required this.chapter, required this.depth});
}

class ChapterTile extends StatelessWidget {
  final TocEntry entry;
  final bool current;
  final VoidCallback onTap;

  const ChapterTile(
      {super.key,
      required this.entry,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTop = entry.depth == 0;
    final title = entry.chapter.title.trim().isNotEmpty
        ? entry.chapter.title.trim()
        : entry.chapter.href;

    return Material(
      // A primary tint rather than AppColors.card: card and surface are both
      // white in light mode, so a card-coloured row is invisible against the
      // sheet. This reads on either theme.
      color: current
          ? AppColors.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full-height accent rail — marks the reading position even when
              // the row scrolls past the title's colour cue.
              Container(
                  width: 3,
                  color: current ? AppColors.primary : Colors.transparent),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.fromLTRB(17 + entry.depth * 16, 15, 20, 15),
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
                            fontWeight: current || isTop
                                ? FontWeight.w700
                                : FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (current) ...[
                        const SizedBox(width: 10),
                        const _CurrentBadge(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "you are here" marker on the current chapter's row.
class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: Colors.white,
              size: 12),
          const SizedBox(width: 5),
          Text(
            ReaderStrings.currentlyReadingBadge,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
