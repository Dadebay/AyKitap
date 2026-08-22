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
    // Fetch the next page a screen or so before the actual bottom, so it's
    // already there by the time the user reaches it rather than after.
    // Whichever grid is on screen loads more; the load calls themselves
    // no-op when one's already in flight or there's nothing left.
    if (notification.metrics.maxScrollExtent - notification.metrics.pixels <
        600) {
      if (_shouldShowResults) {
        _runSearch(loadMore: true);
      } else {
        _loadDiscoverBooks(loadMore: true);
      }
    }
    return false;
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
