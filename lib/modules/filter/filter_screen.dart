import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/filter_strings.dart';
import '../../core/widgets/app_back_button.dart';
import 'controller/filter_controller.dart';
import 'widgets/expandable_filter_section.dart';
import 'widgets/filter_chips.dart';

export 'filter_result.dart' show FilterResult;

/// Filtr Sahypasy — TZ section 6, Surat 4 style: quick chips, collapsible
/// filter sections and a sticky "Netijeleri görkez" button.
class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilterController(),
      child: const _FilterScreenBody(),
    );
  }
}

class _FilterScreenBody extends StatelessWidget {
  const _FilterScreenBody();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<FilterController>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(FilterStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _sectionLabel(FilterStrings.quickFilters),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.quickChips
                      .map((chip) => MultiChip(
                            label: chip,
                            selected: c.activeQuickChips.contains(chip),
                            onTap: () => c.toggleQuickChip(chip),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ExpandableFilterSection(
                        title: FilterStrings.language,
                        summary: c.selectedLanguages.isEmpty ? FilterStrings.any : c.selectedLanguages.map((l) => l.label).join(', '),
                        expanded: c.expanded.contains('lang'),
                        onToggle: () => c.toggleExpanded('lang'),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: BookLanguage.values
                              .map((l) => MultiChip(
                                    label: l.label,
                                    selected: c.selectedLanguages.contains(l),
                                    onTap: () => c.toggleLanguage(l),
                                  ))
                              .toList(),
                        ),
                      ),
                      _divider(),
                      ExpandableFilterSection(
                        title: FilterStrings.format,
                        summary: c.selectedFormats.isEmpty ? FilterStrings.any : c.selectedFormats.map((f) => f.label).join(', '),
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
                      _divider(),
                      ExpandableFilterSection(
                        title: FilterStrings.publishDate,
                        summary: '${c.yearRange.start.round()} – ${c.yearRange.end.round()}',
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
                              labels: RangeLabels(c.yearRange.start.round().toString(), c.yearRange.end.round().toString()),
                              onChanged: c.setYearRange,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${c.yearRange.start.round()}', style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                                  Text('${c.yearRange.end.round()}', style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel(FilterStrings.sorting),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: ExpandableFilterSection(
                    title: FilterStrings.sortOrder,
                    summary: c.sortBy.label,
                    expanded: c.expanded.contains('sort'),
                    onToggle: () => c.toggleExpanded('sort'),
                    child: Column(
                      children: SortBy.values.map((s) => SortTile(label: s.label, value: s, group: c.sortBy, onChanged: (v) => c.setSortBy(v!))).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: c.clear,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: AppColors.grey1, size: 18),
                        const SizedBox(width: 12),
                        Text(FilterStrings.clearFilter, style: TextStyle(color: AppColors.grey1, fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(context, c),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(), style: TextStyle(color: AppColors.grey2, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6));
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 16, endIndent: 16);

  Widget _buildBottomBar(BuildContext context, FilterController c) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context, c.buildResult()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(FilterStrings.showResults, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
