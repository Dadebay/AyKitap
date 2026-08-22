import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../controller/filter_controller.dart';
import 'expandable_filter_section.dart';
import 'filter_chips.dart';

/// "Tertiplemek" label + the single expandable sort-order card, both reading
/// [FilterController] straight from the surrounding [ChangeNotifierProvider]
/// so [FilterScreen] doesn't have to pass it down by hand.
class FilterSortSection extends StatelessWidget {
  const FilterSortSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FilterController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FilterStrings.sorting.toUpperCase(),
          style: TextStyle(
              color: AppColors.grey2,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: ExpandableFilterSection(
            title: FilterStrings.sortOrder,
            summary: c.sortBy.label,
            expanded: c.expanded.contains('sort'),
            onToggle: () => c.toggleExpanded('sort'),
            child: Column(
              children: SortBy.values
                  .map((s) => SortTile(
                      label: s.label,
                      value: s,
                      group: c.sortBy,
                      onChanged: (v) => c.setSortBy(v!)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// The "Filtri arassala" row — resets every [FilterController] selection.
class FilterClearRow extends StatelessWidget {
  const FilterClearRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<FilterController>();
    return InkWell(
      onTap: c.clear,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                color: AppColors.grey1,
                size: 18),
            const SizedBox(width: 12),
            Text(FilterStrings.clearFilter,
                style: TextStyle(
                    color: AppColors.grey1,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
