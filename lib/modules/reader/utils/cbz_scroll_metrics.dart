/// Geometry for the CBZ reader's continuous vertical scroll.
///
/// In that mode every page is drawn at the full viewport *width* and the
/// reader scrolls down the stack, so a tall comic page stays readable instead
/// of being shrunk whole onto the screen. That means page boundaries no longer
/// line up with screen boundaries, and "which page am I on" stops being a
/// [PageController] index — it has to be derived from the scroll offset.
///
/// Each page's height is fixed by its own aspect ratio at that width, so the
/// whole layout is known up front: this turns the list of aspect ratios into
/// cumulative offsets once, then answers both directions of the question
/// (offset → page, page → offset) by lookup rather than by measuring widgets.
///
/// Kept free of Flutter widgets deliberately — it's the part with the easy
/// off-by-one mistakes, so it's unit-tested directly.
class CbzScrollMetrics {
  /// Top edge of each page in scroll coordinates; `_tops[i]` is page i's
  /// offset. Always ascending, one entry per page.
  final List<double> _tops;

  /// Height each page occupies, including the gap drawn under it.
  final List<double> _heights;

  final double totalHeight;

  CbzScrollMetrics._(this._tops, this._heights, this.totalHeight);

  /// [aspectRatios] is width/height per page, in page order. A ratio that is
  /// missing or nonsensical (zero, negative, NaN — an image whose header
  /// couldn't be read) falls back to [fallbackAspectRatio] so one bad page
  /// can't collapse the stack or throw off every page after it.
  factory CbzScrollMetrics({
    required List<double> aspectRatios,
    required double viewportWidth,
    double gap = 0,
    double fallbackAspectRatio = 0.7,
  }) {
    final tops = <double>[];
    final heights = <double>[];
    var running = 0.0;
    for (final raw in aspectRatios) {
      final ratio = (raw.isFinite && raw > 0) ? raw : fallbackAspectRatio;
      final height = viewportWidth / ratio + gap;
      tops.add(running);
      heights.add(height);
      running += height;
    }
    return CbzScrollMetrics._(tops, heights, running);
  }

  int get pageCount => _tops.length;

  /// The page occupying [offset] — the reader's current page. Binary search
  /// rather than a scan: a long manga is thousands of pages and this runs on
  /// every scroll frame.
  int pageAt(double offset) {
    if (_tops.isEmpty) return 0;
    if (offset <= 0) return 0;
    var lo = 0;
    var hi = _tops.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_tops[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Scroll offset that puts page [index]'s top edge at the top of the
  /// viewport. Clamped, so a stale saved page from a re-extracted book can't
  /// scroll into nothing.
  double offsetOf(int index) {
    if (_tops.isEmpty) return 0;
    return _tops[index.clamp(0, _tops.length - 1)];
  }

  /// Height of page [index] including its gap — what the list delegate builds
  /// each item at.
  double heightOf(int index) {
    if (_heights.isEmpty) return 0;
    return _heights[index.clamp(0, _heights.length - 1)];
  }
}
