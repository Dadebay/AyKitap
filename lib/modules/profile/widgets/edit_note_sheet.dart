import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/profile_strings.dart';

/// Full page-style bottom sheet for editing a note's text — matches
/// BookRequestSheet's layout (drag handle, icon header, card text field,
/// full-width primary action) instead of a cramped AlertDialog.
class EditNoteSheet extends StatefulWidget {
  final String initialText;
  const EditNoteSheet({super.key, required this.initialText});

  @override
  State<EditNoteSheet> createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<EditNoteSheet> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Text(ProfileStrings.editNoteTitle, style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text(ProfileStrings.editNoteSubtitle, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: TextStyle(color: AppColors.white, fontSize: 14.5, height: 1.5),
                decoration: InputDecoration(hintText: ProfileStrings.noteTextHint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                onPressed: _save,
                child: Text(ProfileStrings.save, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ProfileStrings.cancel, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
