import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Confirms deleting a note from [NotesScreen] — an icon-badged alert with
/// full-width delete/cancel actions, same shape as the shelf-delete dialog.
/// Returns `true` if the reader confirmed.
Future<bool> showDeleteNoteConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle),
        child: const Center(
            child: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: Colors.redAccent,
                size: 24)),
      ),
      title: Text(
        ProfileStrings.deleteNoteConfirmTitle,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Text(
        ProfileStrings.actionIrreversible,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                onPressed: () => Navigator.pop(context, true),
                child: Text(ProfileStrings.delete,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(ProfileStrings.cancel,
                    style: TextStyle(color: AppColors.grey2, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return confirmed == true;
}
