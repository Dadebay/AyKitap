import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/reading_note.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/profile_strings.dart';

class NoteCard extends StatelessWidget {
  final ReadingNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onGoToBook;
  const NoteCard({super.key, required this.note, required this.onEdit, required this.onDelete, required this.onGoToBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('“', style: TextStyle(color: AppColors.primary, fontSize: 38, fontWeight: FontWeight.w900, height: 0.5)),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(note.text, style: TextStyle(color: AppColors.grey1, fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.grey2, onTap: onEdit),
              const SizedBox(width: 8),
              _ActionIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.redAccent, onTap: onDelete),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onGoToBook,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(note.book.coverImage, width: 32, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ProfileStrings.goToBook, style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.primary, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Center(child: HugeIcon(icon: icon, color: color, size: 14)),
      ),
    );
  }
}
