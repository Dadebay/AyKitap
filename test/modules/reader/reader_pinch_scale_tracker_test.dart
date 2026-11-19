import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakura_epub/src/utils/pinch_scale_tracker.dart';

void main() {
  test('commits one zoom factor and suppresses the matching page swipe', () {
    final pinch = PinchScaleTracker();
    pinch.down(1, Offset.zero);
    pinch.down(2, const Offset(100, 0));
    expect(pinch.suppressTapAndSwipe, isTrue);

    pinch.move(2, const Offset(135, 0));
    expect(pinch.up(2, const Offset(135, 0)), closeTo(1.35, 0.001));
    expect(pinch.suppressTapAndSwipe, isTrue);
    expect(pinch.up(1, Offset.zero), isNull);
    expect(pinch.suppressTapAndSwipe, isFalse);
  });

  test('small movement and one finger do not zoom', () {
    final pinch = PinchScaleTracker();
    pinch.down(1, Offset.zero);
    pinch.move(1, const Offset(80, 0));
    expect(pinch.up(1, const Offset(80, 0)), isNull);

    pinch.down(1, Offset.zero);
    pinch.down(2, const Offset(100, 0));
    pinch.move(2, const Offset(105, 0));
    expect(pinch.up(2, const Offset(105, 0)), isNull);
    pinch.cancel(1);
    expect(pinch.suppressTapAndSwipe, isFalse);
  });

  test('pinching inward returns a smaller factor', () {
    final pinch = PinchScaleTracker();
    pinch.down(1, Offset.zero);
    pinch.down(2, const Offset(100, 0));
    pinch.move(2, const Offset(75, 0));
    expect(pinch.up(2, const Offset(75, 0)), closeTo(0.75, 0.001));
  });
}
