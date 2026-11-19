import 'dart:ui';

/// Tracks a two-finger gesture without repaginating the book on every frame.
/// The scale is committed once when either finger lifts.
class PinchScaleTracker {
  final Map<int, Offset> _points = {};
  int? _first;
  int? _second;
  double _startDistance = 0;
  double _scale = 1;
  bool _wasPinch = false;

  bool get suppressTapAndSwipe => _wasPinch;

  void down(int pointer, Offset position) {
    _points[pointer] = position;
    if (_points.length != 2 || _wasPinch) return;
    final ids = _points.keys.toList();
    _first = ids[0];
    _second = ids[1];
    _startDistance = (_points[_first]! - _points[_second]!).distance;
    _scale = 1;
    _wasPinch = true;
  }

  void move(int pointer, Offset position) {
    if (!_points.containsKey(pointer)) return;
    _points[pointer] = position;
    final first = _first;
    final second = _second;
    if (first == null || second == null || _startDistance < 10) return;
    final a = _points[first];
    final b = _points[second];
    if (a != null && b != null) {
      _scale = (a - b).distance / _startDistance;
    }
  }

  double? up(int pointer, Offset position) {
    move(pointer, position);
    final finishedPair = pointer == _first || pointer == _second;
    _points.remove(pointer);
    double? committed;
    if (finishedPair) {
      if (_startDistance >= 10 && (_scale < 0.92 || _scale > 1.08)) {
        committed = _scale.clamp(0.7, 1.4);
      }
      _first = null;
      _second = null;
    }
    if (_points.isEmpty) _wasPinch = false;
    return committed;
  }

  void cancel(int pointer) {
    _points.remove(pointer);
    if (pointer == _first || pointer == _second) {
      _first = null;
      _second = null;
    }
    if (_points.isEmpty) _wasPinch = false;
  }
}
