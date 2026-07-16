import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/book.dart';
import '../../core/data/mock/mock_data.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/services/analytics_service.dart';
import '../book_detail/book_detail_screen.dart';
import '../filter/filter_screen.dart';
import '../../core/localization/strings/search_strings.dart';
import 'widgets/quick_chip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  // Debounced live query — only set once ≥2 chars have been typed.
  String _query = '';
  // Quick chips selected on this screen.
  final Set<String> _chips = {};
  // Result of the full filter page, if it was applied.
  bool _filterActive = false;
  List<Book>? _filterBooks;

  // Any active filter lights the red badge on the filter button.
  bool get _hasActiveFilters => _filterActive || _chips.isNotEmpty;

  // What the grid shows, in priority order: a live text query, then a
  // returned filter set / selected chips, otherwise the full browse catalogue.
  List<Book> get _gridBooks {
    if (_query.length >= 2) {
      return MockData.generateBooks(18, seed: _query.length * 7 + _query.codeUnitAt(0));
    }
    if (_filterActive && _filterBooks != null) return _filterBooks!;
    if (_chips.isNotEmpty) return MockData.generateBooks(18, seed: _chips.length * 13 + 5);
    return MockData.books;
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Iň az 2 harp ýazylandan soň netijeler peýda bolýar (debounce 300ms).
    if (value.trim().length < 2) {
      if (_query.isNotEmpty) setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final term = value.trim();
      setState(() => _query = term);
      // Fires once per settled query (after the debounce), not per
      // keystroke, so the Analytics console reports what people actually
      // searched for rather than every partial string typed along the way.
      AnalyticsService.instance.logSearch(term);
    });
  }

  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
  }

  void _toggleChip(String chip) {
    setState(() => _chips.contains(chip) ? _chips.remove(chip) : _chips.add(chip));
  }

  Future<void> _openFilter() async {
    final res = await context.push<FilterResult>(const FilterScreen());
    if (res != null && mounted) {
      setState(() {
        _filterActive = res.active;
        _filterBooks = res.books;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = _gridBooks;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(SearchStrings.title, style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildChipsRow(),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid(books)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const SizedBox(width: 14),
            HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.grey2, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: AppColors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: SearchStrings.searchHint,
                  hintStyle: TextStyle(color: AppColors.grey3, fontSize: 14.5),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clearQuery,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.grey2, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // Filter button (opens the full filter page) with a red badge
          // whenever any filter is active.
          GestureDetector(
            onTap: _openFilter,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal, color: AppColors.primary, size: 20),
                ),
                if (_hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          for (final chip in MockData.quickFilterChips) ...[
            QuickChip(label: chip, selected: _chips.contains(chip), onTap: () => _toggleChip(chip)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid(List<Book> books) {
    if (books.isEmpty) {
      return Center(child: Text(SearchStrings.noResults, style: TextStyle(color: AppColors.grey2, fontSize: 15)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        return GestureDetector(
          onTap: () {
            AnalyticsService.instance.logSelectBook(id: book.id, title: book.title);
            context.push(BookDetailScreen(book: book));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: AppColors.card,
              child: Image.asset(book.coverImage, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}
