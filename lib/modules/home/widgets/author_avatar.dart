import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/models/book.dart';
import '../../../core/theme/app_colors.dart';

/// A single circle-avatar + name cell in the HomeScreen "Ýazarlar" row —
/// same colored-circle-with-user-icon placeholder as `AllAuthorsScreen`,
/// just sized to sit in a horizontal strip instead of a grid.
class AuthorAvatar extends StatelessWidget {
  final Author author;
  const AuthorAvatar({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: author.color, shape: BoxShape.circle),
            child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.white70, size: 26)),
          ),
          const SizedBox(height: 10),
          Text(
            author.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.grey1, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
