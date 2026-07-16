import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// The text-selection menu (TZ §12.7): shows the selected passage and the
/// actions available on it — highlight, add note, copy, share. Highlight and
/// note are only offered when [canAnnotate] is true (i.e. the book maps to a
/// catalogue book the profile's Notlar list can link back to).
class SelectionToolbar extends StatelessWidget {
  final String selectedText;
  final Rect? selectionRect;
  final bool canAnnotate;
  final VoidCallback onHighlight;
  final VoidCallback onAddNote;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const SelectionToolbar({
    super.key,
    required this.selectedText,
    required this.selectionRect,
    required this.canAnnotate,
    required this.onHighlight,
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
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16)],
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: Colors.white38, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (canAnnotate) ...[
                  _Action(icon: HugeIcons.strokeRoundedHighlighter, label: ReaderStrings.highlightLabel, onTap: onHighlight),
                  _Action(icon: HugeIcons.strokeRoundedNoteAdd, label: ReaderStrings.noteLabel, onTap: onAddNote),
                ],
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
              HugeIcon(icon: icon, size: 20, color: const Color(0xFFE86B2C)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
