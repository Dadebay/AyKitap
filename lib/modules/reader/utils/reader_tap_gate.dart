import 'dart:ui';

/// Decides whether a touch that ended inside the EPUB WebView was a genuine
/// tap (toggle the reader chrome) or just part of a scroll / page turn.
///
/// This needs more than the WebView's own start/end coordinates.
/// `epubView.js` reports every touch position as `iframeRect.top +
/// touch.clientY` (see its `getNormalizedTouchCoordinates`), while each
/// page-transition mode animates the viewer element with a `translateY(...)`.
/// So while a page is moving, the frame those coordinates are measured in is
/// moving too — by roughly the same distance, in the same direction, as the
/// finger. A scroll then reports a start and an end that are nearly identical
/// and reads as a stationary tap, which is what made the top/bottom bars flip
/// on *every* scroll and left no way to stay in focus mode.
///
/// The WebView delta is therefore only ever the last-resort fallback. Two
/// sounder signals are consulted first:
///
/// * Flutter's own pointer stream (the `Listener` around the viewer in
///   reader_view_body.dart). Its coordinates are in the screen's frame, so
///   they are immune to the moving iframe. Platform views don't forward
///   pointers identically on every platform, hence it stays optional.
/// * Whether the reading position actually changed around this gesture. A
///   relocation means the book moved, which no tap ever does.
class ReaderTapGate {
  ReaderTapGate({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;

  /// Longest a press can be held and still count as a tap.
  static const Duration maxTapHold = Duration(milliseconds: 300);

  /// Furthest the finger may travel and still count as a tap, in logical
  /// pixels, as measured from Flutter's pointer stream.
  static const double maxTapTravel = 12.0;

  /// Fallback travel budget against the WebView's own normalised (0–1)
  /// coordinates, used only when Flutter saw no pointer stream for the
  /// gesture. Deliberately tight, since those coordinates under-report
  /// movement rather than over-report it (see the class doc).
  static const double maxTapTravelNormalized = 0.03;

  /// How long a finished Flutter gesture stays authoritative. The WebView's
  /// touch-up crosses an async JS bridge, so it lands a little *after*
  /// Flutter's own pointer-up for the same finger.
  static const Duration pointerGestureGrace = Duration(milliseconds: 600);

  /// A relocation this close to the gesture — at any point from just before
  /// it started through to now — means the book moved: a scroll or a page
  /// turn, not a tap. Covers both orderings, since a transition can report
  /// its relocation either side of the finger lifting.
  static const Duration relocationGrace = Duration(milliseconds: 450);

  /// An unmatched touch-down older than this is treated as abandoned, so a
  /// dropped touch-up can't wedge the gate shut for the rest of the session.
  static const Duration staleTouchDown = Duration(seconds: 2);

  // ── Flutter pointer stream (accurate, screen-space, optional) ───────────
  Offset? _pointerStart;
  double _pointerTravel = 0;
  double? _lastPointerTravel;
  DateTime? _lastPointerUpAt;

  // ── WebView touch stream (drives the decision; coordinates unreliable) ──
  Offset? _webStart;
  DateTime? _webStartAt;

  void pointerDown(Offset position) {
    _pointerStart = position;
    _pointerTravel = 0;
  }

  void pointerMove(Offset position) {
    final start = _pointerStart;
    if (start == null) return;
    final travelled = (position - start).distance;
    if (travelled > _pointerTravel) _pointerTravel = travelled;
  }

  void pointerUp(Offset position) {
    if (_pointerStart == null) return;
    pointerMove(position);
    _lastPointerTravel = _pointerTravel;
    _lastPointerUpAt = _now();
    _pointerStart = null;
  }

  /// Drops the in-flight measurement without recording it. A cancel usually
  /// means the platform view claimed the gesture, which says nothing about
  /// whether it was a tap — so this falls back to the other signals rather
  /// than scoring the gesture either way.
  void pointerCancel() => _pointerStart = null;

  void webTouchDown(double x, double y) {
    final now = _now();
    final startedAt = _webStartAt;
    // epubView.js attaches touch listeners to the iframe document, the parent
    // document and the window, each debounced only against itself, so one
    // physical touch is reported more than once. Keep the first: letting a
    // duplicate re-anchor the gesture mid-scroll is the other way a long drag
    // ends up looking like it started where it ended.
    if (startedAt != null && now.difference(startedAt) < staleTouchDown) return;
    _webStart = Offset(x, y);
    _webStartAt = now;
  }

  /// Whether the touch-up just reported by the WebView should toggle the
  /// reader chrome. [lastRelocationAt] is when the book last changed
  /// position (`ReaderProvider.lastRelocationAt`), or null if it hasn't.
  bool webTouchUpIsTap(double x, double y, {DateTime? lastRelocationAt}) {
    final start = _webStart;
    final startedAt = _webStartAt;
    _webStart = null;
    _webStartAt = null;
    // A touch-up with no live touch-down is a duplicate of one already
    // handled — never a fresh tap.
    if (start == null || startedAt == null) return false;

    final now = _now();
    if (now.difference(startedAt) > maxTapHold) return false;

    if (lastRelocationAt != null &&
        !lastRelocationAt.isBefore(startedAt.subtract(relocationGrace))) {
      return false;
    }

    final travel = _pointerTravelFor(now);
    if (travel != null) return travel <= maxTapTravel;
    return (Offset(x, y) - start).distance <= maxTapTravelNormalized;
  }

  /// Travel Flutter measured for the gesture this touch-up belongs to, or
  /// null when Flutter saw no pointer stream for it.
  double? _pointerTravelFor(DateTime now) {
    // Still down: the WebView's touch-up beat Flutter's pointer-up here.
    if (_pointerStart != null) return _pointerTravel;
    final endedAt = _lastPointerUpAt;
    final travel = _lastPointerTravel;
    if (endedAt == null || travel == null) return null;
    if (now.difference(endedAt) > pointerGestureGrace) return null;
    return travel;
  }

  void reset() {
    _pointerStart = null;
    _pointerTravel = 0;
    _lastPointerTravel = null;
    _lastPointerUpAt = null;
    _webStart = null;
    _webStartAt = null;
  }
}
