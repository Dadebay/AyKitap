part of 'search_sheet.dart';

sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  final String title;
  final int count;
  const _HeaderRow(this.title, this.count);
}

class _HitRow extends _Row {
  final EpubSearchResult result;
  const _HitRow(this.result);
}

/// The results list — chapter-header + hit rows, the capped-results note,
/// and the empty/loading/too-short hint states. Everything in [SearchSheet]
/// that depends on [_SearchSheetState._rows].
extension _SearchSheetResults on _SearchSheetState {
  Widget _body() {
    final typed = _controller.text.trim();

    if (_searching && _rows.isEmpty) {
      return _hint(
          HugeIcons.strokeRoundedSearch01, ReaderSearchStrings.searchSearching);
    }
    if (typed.isEmpty) {
      return _hint(
          HugeIcons.strokeRoundedSearch01, ReaderSearchStrings.searchPrompt);
    }
    if (typed.length < _SearchSheetState._minQueryLength) {
      return _hint(
          HugeIcons.strokeRoundedSearch01, ReaderSearchStrings.searchTooShort);
    }
    if (_rows.isEmpty) {
      // Nothing came back yet for a query long enough to search — either the
      // debounce hasn't fired or the search genuinely found nothing.
      if (_activeQuery.isEmpty) {
        return _hint(
            HugeIcons.strokeRoundedSearch01, ReaderSearchStrings.searchPrompt);
      }
      return _hint(HugeIcons.strokeRoundedSearch01,
          ReaderSearchStrings.searchNoResultsFor(_activeQuery));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: _rows.length,
      itemBuilder: (_, i) {
        final row = _rows[i];
        if (row is _HeaderRow) return _chapterHeader(row);
        return _hitTile((row as _HitRow).result);
      },
    );
  }

  Widget _chapterHeader(_HeaderRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedBookOpen01,
              color: AppColors.primary,
              size: 14),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              row.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.grey1,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${row.count}',
            style: TextStyle(
                color: AppColors.grey3,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _hitTile(EpubSearchResult r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.provider.epubController.display(cfi: r.cfi);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2.5,
                height: 34,
                margin: const EdgeInsets.only(top: 2, right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                      children: _highlight(_clean(r.excerpt), _activeQuery)),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cappedNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        ReaderSearchStrings.searchCapped(EpubController.searchResultLimit),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.grey2, fontSize: 11.5),
      ),
    );
  }
}
