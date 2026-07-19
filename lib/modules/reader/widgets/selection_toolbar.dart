import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The text-selection menu (TZ §12.7): shows the selected passage and the
/// actions available on it — add note, copy, share.
///
/// Styled from [AppColors] like every other reader sheet (settings,
/// bookmarks, chapters, search) — it's a UI chrome element floating over the
/// page, not part of the page itself, so it follows the app's light/dark
/// theme rather than the EPUB reader's page colour (white/sepia/dark/black).
///
/// "Not" opens the add-note sheet, which carries the colour picker: the chosen
/// colour is what the passage gets highlighted in once the note is saved. The
/// note action appears only when [canAnnotate] is true.
class SelectionToolbar extends StatelessWidget {
  final String selectedText;
  final Rect? selectionRect;
  final bool canAnnotate;

  final VoidCallback onAddNote;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const SelectionToolbar({
    super.key,
    required this.selectedText,
    required this.selectionRect,
    required this.canAnnotate,
    required this.onAddNote,
    required this.onCopy,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '"${selectedText.length > 80 ? '${selectedText.substring(0, 80)}…' : selectedText}"',
                    style: TextStyle(color: AppColors.grey2, fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.grey3, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (canAnnotate)
                  _Action(icon: HugeIcons.strokeRoundedNoteAdd, label: ReaderStrings.noteLabel, onTap: onAddNote),
                _Action(icon: HugeIcons.strokeRoundedCopy01, label: ReaderStrings.copyLabel, onTap: onCopy),
                _Action(icon: HugeIcons.strokeRoundedShare08, label: ReaderStrings.shareLabel, onTap: onShare),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 20, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: AppColors.grey1, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
