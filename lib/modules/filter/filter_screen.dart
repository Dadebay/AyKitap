import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/localization/strings/filter_strings.dart';

/// Returned to the SearchScreen when "Netijeleri görkez" is pressed —
/// whether any filter is set (drives the red badge) and the books to show.
class FilterResult {
  final bool active;
  final List<Book> books;
  const FilterResult({required this.active, required this.books});
}

enum _SortBy { name, publishNewOld, publishOldNew, uploadNewOld }

extension _SortLabel on _SortBy {
  String get label {
    switch (this) {
      case _SortBy.name:
        return FilterStrings.sortByName;
      case _SortBy.publishNewOld:
        return FilterStrings.sortByPublishNewOld;
      case _SortBy.publishOldNew:
        return FilterStrings.sortByPublishOldNew;
      case _SortBy.uploadNewOld:
        return FilterStrings.sortByUploadNewOld;
    }
  }
}

// Selection state keys off these enums rather than the display label text —
// labels are locale-dependent (via FilterStrings), so keying a Set<String>
// off them would silently drop selections when the language changes mid-session.
enum _BookLanguage { turkish, russian, english, turkmen, other }

extension _BookLanguageLabel on _BookLanguage {
  String get label {
    switch (this) {
      case _BookLanguage.turkish:
        return FilterStrings.langTurkish;
      case _BookLanguage.russian:
        return FilterStrings.langRussian;
      case _BookLanguage.english:
        return FilterStrings.langEnglish;
      case _BookLanguage.turkmen:
        return FilterStrings.langTurkmen;
      case _BookLanguage.other:
        return FilterStrings.langOther;
    }
  }
}

enum _BookFormatFilter { epub, pdf, mobi, cbzManga }

extension _BookFormatFilterLabel on _BookFormatFilter {
  String get label {
    switch (this) {
      case _BookFormatFilter.epub:
        return FilterStrings.formatEpub;
      case _BookFormatFilter.pdf:
        return FilterStrings.formatPdf;
      case _BookFormatFilter.mobi:
        return FilterStrings.formatMobi;
      case _BookFormatFilter.cbzManga:
        return FilterStrings.formatCbzManga;
    }
  }
}

/// Filtr Sahypasy — TZ section 6, Surat 4 style: quick chips, collapsible
/// filter sections and a sticky "Netijeleri görkez" button.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _quickChips = MockData.quickFilterChips;
  final Set<String> _activeQuickChips = {};

  final Set<_BookLanguage> _selectedLanguages = {};
  final Set<_BookFormatFilter> _selectedFormats = {};
  RangeValues _yearRange = const RangeValues(1990, 2026);
  _SortBy _sortBy = _SortBy.name;

  // Which collapsible sections are open.
  final Set<String> _expanded = {};

  bool get _hasActiveFilters => _activeQuickChips.isNotEmpty || _selectedLanguages.isNotEmpty || _selectedFormats.isNotEmpty || _yearRange != const RangeValues(1990, 2026) || _sortBy != _SortBy.name;

  void _clearFilters() {
    setState(() {
      _activeQuickChips.clear();
      _selectedLanguages.clear();
      _selectedFormats.clear();
      _yearRange = const RangeValues(1990, 2026);
      _sortBy = _SortBy.name;
    });
  }

  void _showResults() {
    // Mock: the concrete filter values just seed a fresh book set.
    final seed = _activeQuickChips.length * 11 + _selectedLanguages.length * 7 + _selectedFormats.length * 5 + _yearRange.start.round() % 50 + _sortBy.index;
    Navigator.pop(
      context,
      FilterResult(active: _hasActiveFilters, books: MockData.generateBooks(18, seed: seed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        centerTitle: true,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
                  children: _quickChips
                      .map((c) => _MultiChip(
                            label: c,
                            selected: _activeQuickChips.contains(c),
                            onTap: () => setState(() => _activeQuickChips.contains(c) ? _activeQuickChips.remove(c) : _activeQuickChips.add(c)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _expandRow(
                        id: 'lang',
                        title: FilterStrings.language,
                        summary: _selectedLanguages.isEmpty ? FilterStrings.any : _selectedLanguages.map((l) => l.label).join(', '),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _BookLanguage.values
                              .map((l) => _MultiChip(
                                    label: l.label,
                                    selected: _selectedLanguages.contains(l),
                                    onTap: () => setState(() => _selectedLanguages.contains(l) ? _selectedLanguages.remove(l) : _selectedLanguages.add(l)),
                                  ))
                              .toList(),
                        ),
                      ),
                      _divider(),
                      _expandRow(
                        id: 'format',
                        title: FilterStrings.format,
                        summary: _selectedFormats.isEmpty ? FilterStrings.any : _selectedFormats.map((f) => f.label).join(', '),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _BookFormatFilter.values
                              .map((f) => _MultiChip(
                                    label: f.label,
                                    selected: _selectedFormats.contains(f),
                                    onTap: () => setState(() => _selectedFormats.contains(f) ? _selectedFormats.remove(f) : _selectedFormats.add(f)),
                                  ))
                              .toList(),
                        ),
                      ),
                      _divider(),
                      _expandRow(
                        id: 'year',
                        title: FilterStrings.publishDate,
                        summary: '${_yearRange.start.round()} – ${_yearRange.end.round()}',
                        child: Column(
                          children: [
                            RangeSlider(
                              values: _yearRange,
                              min: 1950,
                              max: 2026,
                              divisions: 76,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.border,
                              labels: RangeLabels(_yearRange.start.round().toString(), _yearRange.end.round().toString()),
                              onChanged: (v) => setState(() => _yearRange = v),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${_yearRange.start.round()}', style: TextStyle(color: AppColors.grey2, fontSize: 12)),
                                  Text('${_yearRange.end.round()}', style: TextStyle(color: AppColors.grey2, fontSize: 12)),
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
                  child: _expandRow(
                    id: 'sort',
                    title: FilterStrings.sortOrder,
                    summary: _sortBy.label,
                    child: Column(
                      children: _SortBy.values.map((s) => _SortTile(label: s.label, value: s, group: _sortBy, onChanged: (v) => setState(() => _sortBy = v!))).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _clearFilters,
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
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text.toUpperCase(), style: TextStyle(color: AppColors.grey2, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6));
  }

  Widget _divider() => Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.5), indent: 16, endIndent: 16);

  Widget _expandRow({required String id, required String title, required String summary, required Widget child}) {
    final open = _expanded.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => open ? _expanded.remove(id) : _expanded.add(id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                Expanded(
                  child: Text(
                    summary,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.grey2, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
          crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
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
          onPressed: _showResults,
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

class _MultiChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MultiChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SortTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final T group;
  final ValueChanged<T?> onChanged;
  const _SortTile({required this.label, required this.value, required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            HugeIcon(
              icon: selected ? HugeIcons.strokeRoundedCheckmarkCircle01 : HugeIcons.strokeRoundedCircle,
              color: selected ? AppColors.primary : AppColors.grey3,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: TextStyle(color: selected ? AppColors.white : AppColors.grey2, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ),
          ],
        ),
      ),
    );
  }
}
