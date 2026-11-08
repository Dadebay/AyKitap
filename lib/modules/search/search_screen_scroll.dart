part of 'search_screen.dart';

/// The header-collapse-on-scroll behaviour and the load-more trigger that
/// rides along on the same scroll notification.
extension _SearchScreenScroll on _SearchScreenState {
  // Collapse as soon as the grid leaves its top, expand only when it's back
  // there — matching "scroll down to read, scroll up to the start to get the
  // controls back" rather than reacting to every flick of direction.
  //
  // The threshold is a few pixels rather than 0 so an overscroll bounce (or
  // a keyboard-driven relayout) doesn't strobe the header, and horizontal
  // notifications from the chip row are ignored outright.
  bool _onResultsScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final collapsed = notification.metrics.pixels > 12;
    if (collapsed != _headerCollapsed) {
      _setState(() => _headerCollapsed = collapsed);
    }
    _maybeLoadMore();
    return false;
  }

  /// How close to the bottom the grid has to be before the next page is
  /// fetched — roughly a screen, so it has arrived by the time the reader
  /// gets there rather than after.
  static const _loadMoreThreshold = 600.0;

  /// Fetches the next page if the grid on screen is near its end.
  ///
  /// Reads the live [ScrollController] rather than a notification's metrics,
  /// because the two moments that need this check most produce no scroll
  /// notification at all:
  ///
  /// * A page landing while the reader rests at the bottom. Appending rows
  ///   changes the scroll *metrics*, which dispatches a
  ///   `ScrollMetricsNotification` — not a [ScrollNotification], so the
  ///   listener above never sees it. That is why paging appeared to stop at
  ///   the bottom and only resumed after scrolling up and back down: that
  ///   round trip was the reader manually generating the notification the
  ///   grid needed.
  /// * A first page too short to fill the screen. Nothing can be scrolled,
  ///   so no notification is ever produced and the grid stays at one page.
  ///
  /// [_scheduleLoadMoreCheck] is what re-runs it after each load completes.
  void _maybeLoadMore() {
    final controller =
        _searchMode == _SearchMode.author ? _authorGridScroll : _bookGridScroll;
    // No grid attached: a spinner, an error or an empty state is showing.
    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      return;
    }
    final position = controller.position;
    if (position.maxScrollExtent - position.pixels >= _loadMoreThreshold) {
      return;
    }
    // The load calls themselves no-op when one's already in flight or there
    // is nothing left, which is also what stops this from looping.
    if (_shouldShowResults) {
      _runSearch(loadMore: true);
    } else if (_searchMode == _SearchMode.author) {
      // Author mode's discover grid has its own list to extend — this used
      // to call [_loadDiscoverBooks] whichever mode was showing, so
      // scrolling the author tab paged the (invisible) book grid and the
      // authors never grew past their first request.
      _loadDiscoverAuthors(loadMore: true);
    } else {
      _loadDiscoverBooks(loadMore: true);
    }
  }

  /// Re-checks once the newly loaded rows have actually been laid out —
  /// after the frame, so [_maybeLoadMore] reads the grown
  /// `maxScrollExtent` rather than the one from before the page arrived.
  void _scheduleLoadMoreCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeLoadMore();
    });
  }

  /// Wraps a header row so it fades *and* gives its height back to the grid
  /// as it goes — [AnimatedCrossFade] against an empty box animates both,
  /// which a plain [AnimatedOpacity] wouldn't (it would leave a hole).
  Widget _collapsibleHeader({required Widget child}) {
    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState: _headerCollapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 260),
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      sizeCurve: Curves.easeOutCubic,
    );
  }
}
