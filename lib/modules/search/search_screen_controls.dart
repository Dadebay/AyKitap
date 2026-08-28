part of 'search_screen.dart';

/// The search text field, the Kitap/Ýazar mode toggle and the filter/genre
/// chips row — the controls sitting above the results/discover grid.
extension _SearchScreenControls on _SearchScreenState {
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const SizedBox(width: 14),
            HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: AppColors.grey2,
                size: 20),
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
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: AppColors.grey2,
                      size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // "Kitap" / "Ýazar" pill — governs whether the typed text goes to the
  // backend's `search` (title) or `authors` (author name) param.
  //
  // The stock iOS control rather than a hand-rolled one: its thumb slides
  // between segments with the real spring curve, shrinks under the finger,
  // and can be *dragged* across — behaviour that a plain AnimatedContainer
  // per segment (which just cross-faded two background colors) can't
  // reproduce. Colors are overridden to the app's own, so only the motion is
  // Cupertino.
  Widget _buildSearchModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The control sizes every segment to its widest child and then lets
          // the whole box stretch, which would leave both pills huddled at
          // the left of a full-width row. Handing the labels half the row
          // each is what makes the thumb travel the full distance — the
          // control clamps anything wider back to an exact half.
          final segmentWidth = (constraints.maxWidth - 12) / 2;
          return CupertinoSlidingSegmentedControl<_SearchMode>(
            groupValue: _searchMode,
            backgroundColor: AppColors.card,
            thumbColor: AppColors.primary,
            padding: const EdgeInsets.all(3),
            // Non-null only when the value actually changes, and
            // [_setSearchMode] no-ops on a repeat anyway.
            onValueChanged: (mode) => _setSearchMode(mode ?? _searchMode),
            children: {
              _SearchMode.book: _searchModeLabel(
                  SearchStrings.searchByBook, _SearchMode.book, segmentWidth),
              _SearchMode.author: _searchModeLabel(SearchStrings.searchByAuthor,
                  _SearchMode.author, segmentWidth),
            },
          );
        },
      ),
    );
  }

  Widget _searchModeLabel(String label, _SearchMode mode, double width) {
    final selected = _searchMode == mode;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          label,
          textAlign: TextAlign.center,
          // The thumb carries the motion; the label only has to stay legible
          // against whichever color ends up under it.
          style: TextStyle(
              color: selected ? Colors.white : AppColors.grey2,
              fontSize: 13,
              fontWeight: FontWeight.w700),
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
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12)),
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFilterHorizontal,
                      color: AppColors.primary,
                      size: 20),
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
          // Real genres (`GET /genres/all`) — tapping one selects it in
          // place (combined with any text query) rather than navigating
          // away; tapping the selected one again clears it.
          //
          // Shown in both modes. `GET /authors/search` takes nothing but
          // `search`, so a genre can't narrow author results — but hiding
          // the row in Ýazar mode made it jump in and out as the toggle
          // moved, and left the user no way back to a genre from there.
          // Instead the chips stay put and [_toggleGenre] switches the
          // toggle back to Kitap, where the tap actually means something.
          for (final (i, genre) in (_genres ?? const []).indexed) ...[
            StaggerFadeIn(
              index: i,
              child: QuickChip(
                  label: genre.name,
                  selected: _selectedGenreId == genre.id,
                  onTap: () => _toggleGenre(genre)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
