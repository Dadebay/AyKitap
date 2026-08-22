import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/author_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'author_books_sort.dart';

/// The A→Z / by-date sort popup button above [CatalogAuthorDetailScreen]'s
/// book grid. Picking the already-active sort turns it back off (server
/// order) instead of being a no-op — see [onChanged].
class AuthorBooksSortButton extends StatelessWidget {
  final AuthorBooksSort? sort;
  final ValueChanged<AuthorBooksSort?> onChanged;

  const AuthorBooksSortButton(
      {super.key, required this.sort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AuthorBooksSort>(
      onSelected: (value) => onChanged(sort == value ? null : value),
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _sortMenuItem(AuthorBooksSort.name, AuthorStrings.sortAZ,
            HugeIcons.strokeRoundedSortingAZ01),
        _sortMenuItem(AuthorBooksSort.date, AuthorStrings.sortByDate,
            HugeIcons.strokeRoundedCalendar03),
      ],
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration:
            BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedSortingAZ01,
          color: sort != null ? AppColors.primary : AppColors.grey1,
          size: 18,
        ),
      ),
    );
  }

  PopupMenuItem<AuthorBooksSort> _sortMenuItem(
      AuthorBooksSort value, String label, List<List<dynamic>> icon) {
    final selected = sort == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
              icon: icon,
              color: selected ? AppColors.primary : AppColors.grey1,
              size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
