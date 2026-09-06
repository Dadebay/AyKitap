import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/filter_strings.dart';
import '../../core/widgets/app_back_button.dart';
import 'controller/filter_controller.dart';
import 'widgets/filter_bottom_bar.dart';
import 'widgets/filter_quick_sections.dart';
import 'widgets/filter_sort_and_clear.dart';

export 'filter_result.dart' show FilterResult;

/// Filtr Sahypasy — TZ section 6, Surat 4 style: quick chips, collapsible
/// filter sections and a sticky "Netijeleri görkez" button.
class FilterScreen extends StatelessWidget {
  /// The genres, languages, formats, year window and sort already applied by
  /// the caller, re-selected when the page opens so the filter shows the
  /// state that's actually in effect.
  final Set<int> initialGenreIds;
  final Set<int> initialLanguageIds;
  final Set<BookFormatFilter> initialFormats;
  final RangeValues? initialYearRange;
  final SortBy? initialSortBy;

  const FilterScreen({
    super.key,
    this.initialGenreIds = const {},
    this.initialLanguageIds = const {},
    this.initialFormats = const {},
    this.initialYearRange,
    this.initialSortBy,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilterController(
        initialGenreIds: initialGenreIds,
        initialLanguageIds: initialLanguageIds,
        initialFormats: initialFormats,
        initialYearRange: initialYearRange,
        initialSortBy: initialSortBy,
      ),
      child: const _FilterScreenBody(),
    );
  }
}

class _FilterScreenBody extends StatelessWidget {
  const _FilterScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        centerTitle: true,
        leading: const AppBackButton(size: 20),
        title: Text(FilterStrings.title,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: const [
                SizedBox(height: 20),
                FilterQuickSections(),
                SizedBox(height: 20),
                FilterSortSection(),
                SizedBox(height: 14),
                FilterClearRow(),
              ],
            ),
          ),
          const FilterBottomBar(),
        ],
      ),
    );
  }
}
