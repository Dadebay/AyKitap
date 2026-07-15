import 'package:flutter/material.dart';
import '../../../core/localization/strings/reader_strings.dart';

class SelectionToolbar extends StatelessWidget {
  final String selectedText;
  final Rect? selectionRect;
  final VoidCallback onCopy;
  final VoidCallback onClose;

  const SelectionToolbar({
    super.key,
    required this.selectedText,
    required this.selectionRect,
    required this.onCopy,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '"${selectedText.length > 60 ? '${selectedText.substring(0, 60)}...' : selectedText}"',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 16, color: Color(0xFFE86B2C)),
              label: Text(ReaderStrings.copyLabel, style: const TextStyle(color: Color(0xFFE86B2C), fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
