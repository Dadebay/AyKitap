import 'package:flutter/material.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Name, book count and expandable bio at the top of
/// [CatalogAuthorDetailScreen]'s content — controlled from outside
/// ([expanded]/[onToggleExpanded]) since the screen owns that bit of state.
class AuthorBioSection extends StatelessWidget {
  final String name;
  final int bookCount;
  final String? bio;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const AuthorBioSection({
    super.key,
    required this.name,
    required this.bookCount,
    required this.bio,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
        if (bookCount > 0) ...[
          const SizedBox(height: 4),
          Text(AuthorStrings.booksCountLabel(bookCount),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey2, fontSize: 13)),
        ],
        if (bio != null && bio!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            bio!,
            maxLines: expanded ? null : 5,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style:
                TextStyle(color: AppColors.grey1, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onToggleExpanded,
            child: Text(
              expanded ? AuthorStrings.showLess : AuthorStrings.readMore,
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
