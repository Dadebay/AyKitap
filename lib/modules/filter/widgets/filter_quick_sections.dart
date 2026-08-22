import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../controller/filter_controller.dart';
import 'expandable_filter_section.dart';
import 'filter_chips.dart';
import 'filter_language_genre_options.dart';

/// The card of collapsible sections — Dil / Žanr / Format / Çap senesi —
/// [FilterScreen]'s main body. Each row is filtered against
/// [FilterController], watched here so every section repaints on its own
/// slice of state without the whole screen re-running its build.
class FilterQuickSections extends StatelessWidget {
  const FilterQuickSections({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FilterController>();
    return Container(
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ExpandableFilterSection(
            title: FilterStrings.language,
            summary: c.selectedLanguageIds.isEmpty
                ? FilterStrings.any
                : c.selectedLanguagesLabel,
            expanded: c.expanded.contains('lang'),
            onToggle: () => c.toggleExpanded('lang'),
            child: LanguageOptions(c),
          ),
          const _SectionDivider(),
          ExpandableFilterSection(
            title: FilterStrings.genre,
            summary: c.selectedGenreId == null
                ? FilterStrings.any
                : (c.selectedGenreLabel ?? FilterStrings.any),
            expanded: c.expanded.contains('genre'),
            onToggle: () => c.toggleExpanded('genre'),
            child: GenreOptions(c),
          ),
          const _SectionDivider(),
          ExpandableFilterSection(
            title: FilterStrings.format,
            summary: c.selectedFormats.isEmpty
                ? FilterStrings.any
                : c.selectedFormats.map((f) => f.label).join(', '),
            expanded: c.expanded.contains('format'),
            onToggle: () => c.toggleExpanded('format'),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BookFormatFilter.values
                  .map((f) => MultiChip(
                        label: f.label,
                        selected: c.selectedFormats.contains(f),
                        onTap: () => c.toggleFormat(f),
                      ))
                  .toList(),
            ),
          ),
          const _SectionDivider(),
          ExpandableFilterSection(
            title: FilterStrings.publishDate,
            summary:
                '${c.yearRange.start.round()} – ${c.yearRange.end.round()}',
            expanded: c.expanded.contains('year'),
            onToggle: () => c.toggleExpanded('year'),
            child: Column(
              children: [
                RangeSlider(
                  values: c.yearRange,
                  min: 1950,
                  max: 2026,
                  divisions: 76,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  labels: RangeLabels(c.yearRange.start.round().toString(),
                      c.yearRange.end.round().toString()),
                  onChanged: c.setYearRange,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${c.yearRange.start.round()}',
                          style:
                              TextStyle(color: AppColors.grey2, fontSize: 12)),
                      Text('${c.yearRange.end.round()}',
                          style:
                              TextStyle(color: AppColors.grey2, fontSize: 12)),
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border.withValues(alpha: 0.5),
      indent: 16,
      endIndent: 16);
}
