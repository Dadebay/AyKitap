import 'package:flutter/material.dart';
import '../../../core/data/mock/mock_data.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../filter_result.dart';

enum SortBy { name, publishNewOld, publishOldNew, uploadNewOld }

extension SortByLabel on SortBy {
  String get label {
    switch (this) {
      case SortBy.name:
        return FilterStrings.sortByName;
      case SortBy.publishNewOld:
        return FilterStrings.sortByPublishNewOld;
      case SortBy.publishOldNew:
        return FilterStrings.sortByPublishOldNew;
      case SortBy.uploadNewOld:
        return FilterStrings.sortByUploadNewOld;
    }
  }
}

// Selection state keys off these enums rather than the display label text —
// labels are locale-dependent (via FilterStrings), so keying a Set<String>
// off them would silently drop selections when the language changes mid-session.
enum BookLanguage { turkish, russian, english, turkmen, other }

extension BookLanguageLabel on BookLanguage {
  String get label {
    switch (this) {
      case BookLanguage.turkish:
        return FilterStrings.langTurkish;
      case BookLanguage.russian:
        return FilterStrings.langRussian;
      case BookLanguage.english:
        return FilterStrings.langEnglish;
      case BookLanguage.turkmen:
        return FilterStrings.langTurkmen;
      case BookLanguage.other:
        return FilterStrings.langOther;
    }
  }
}

enum BookFormatFilter { epub, pdf, mobi, cbzManga }

extension BookFormatFilterLabel on BookFormatFilter {
  String get label {
    switch (this) {
      case BookFormatFilter.epub:
        return FilterStrings.formatEpub;
      case BookFormatFilter.pdf:
        return FilterStrings.formatPdf;
      case BookFormatFilter.mobi:
        return FilterStrings.formatMobi;
      case BookFormatFilter.cbzManga:
        return FilterStrings.formatCbzManga;
    }
  }
}

const kDefaultYearRange = RangeValues(1990, 2026);

/// Owns every bit of selection state on [FilterScreen] — quick chips,
/// language/format multi-select, year range, sort order, and which
/// collapsible section is open — so the screen itself just renders it.
class FilterController extends ChangeNotifier {
  final quickChips = MockData.quickFilterChips;
  final Set<String> activeQuickChips = {};
  final Set<BookLanguage> selectedLanguages = {};
  final Set<BookFormatFilter> selectedFormats = {};
  RangeValues yearRange = kDefaultYearRange;
  SortBy sortBy = SortBy.name;

  // Which collapsible sections are open.
  final Set<String> expanded = {};

  bool get hasActiveFilters =>
      activeQuickChips.isNotEmpty || selectedLanguages.isNotEmpty || selectedFormats.isNotEmpty || yearRange != kDefaultYearRange || sortBy != SortBy.name;

  void toggleQuickChip(String chip) {
    activeQuickChips.contains(chip) ? activeQuickChips.remove(chip) : activeQuickChips.add(chip);
    notifyListeners();
  }

  void toggleLanguage(BookLanguage lang) {
    selectedLanguages.contains(lang) ? selectedLanguages.remove(lang) : selectedLanguages.add(lang);
    notifyListeners();
  }

  void toggleFormat(BookFormatFilter format) {
    selectedFormats.contains(format) ? selectedFormats.remove(format) : selectedFormats.add(format);
    notifyListeners();
  }

  void setYearRange(RangeValues v) {
    yearRange = v;
    notifyListeners();
  }

  void setSortBy(SortBy s) {
    sortBy = s;
    notifyListeners();
  }

  void toggleExpanded(String id) {
    expanded.contains(id) ? expanded.remove(id) : expanded.add(id);
    notifyListeners();
  }

  void clear() {
    activeQuickChips.clear();
    selectedLanguages.clear();
    selectedFormats.clear();
    yearRange = kDefaultYearRange;
    sortBy = SortBy.name;
    notifyListeners();
  }

  // Mock: the concrete filter values just seed a fresh book set.
  FilterResult buildResult() {
    final seed = activeQuickChips.length * 11 + selectedLanguages.length * 7 + selectedFormats.length * 5 + yearRange.start.round() % 50 + sortBy.index;
    return FilterResult(active: hasActiveFilters, books: MockData.generateBooks(18, seed: seed));
  }
}
