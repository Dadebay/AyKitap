import 'package:aykitap/modules/reader/utils/reader_tap_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late ReaderTapGate gate;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    gate = ReaderTapGate(clock: () => now);
  });

  void advance(int ms) => now = now.add(Duration(milliseconds: ms));

  group('genuine taps', () {
    test('a still, short press toggles the chrome', () {
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(80);
      gate.pointerUp(const Offset(202, 401));

      expect(gate.webTouchUpIsTap(0.5, 0.5), isTrue);
    });

    test('a relocation from well before the gesture does not block it', () {
      final oldRelocation = now.subtract(const Duration(seconds: 2));
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(80);
      gate.pointerUp(const Offset(200, 400));

      expect(
        gate.webTouchUpIsTap(0.5, 0.5, lastRelocationAt: oldRelocation),
        isTrue,
      );
    });

    test('falls back to the WebView delta when Flutter saw no pointers', () {
      gate.webTouchDown(0.5, 0.5);
      advance(90);

      expect(gate.webTouchUpIsTap(0.505, 0.502), isTrue);
    });
  });

  group('scrolls must not toggle the chrome', () {
    // The regression this class exists for: epubView.js measures touches
    // against the iframe's own box, and a page transition translates that box
    // by roughly the distance the finger moves — so a scroll reports a start
    // and an end that are almost identical. Flutter's pointer stream is what
    // still sees the real 300px drag.
    test('a drag the WebView reports as stationary is still a scroll', () {
      gate.pointerDown(const Offset(200, 700));
      gate.webTouchDown(0.5, 0.87);
      advance(150);
      gate.pointerMove(const Offset(200, 400));
      gate.pointerUp(const Offset(200, 400));

      expect(gate.webTouchUpIsTap(0.5, 0.86), isFalse);
    });

    test('a relocation during the gesture rejects it even when it looks still',
        () {
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(100);
      final relocatedAt = now;
      advance(50);
      gate.pointerUp(const Offset(200, 400));

      expect(
        gate.webTouchUpIsTap(0.5, 0.5, lastRelocationAt: relocatedAt),
        isFalse,
      );
    });

    test('a relocation just before the gesture rejects it too', () {
      // The transition can report its relocation either side of the finger
      // lifting, so the grace window reaches backwards as well.
      final relocatedAt = now;
      advance(100);
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(80);
      gate.pointerUp(const Offset(200, 400));

      expect(
        gate.webTouchUpIsTap(0.5, 0.5, lastRelocationAt: relocatedAt),
        isFalse,
      );
    });

    test('a long press (text selection) is not a tap', () {
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(700);
      gate.pointerUp(const Offset(200, 400));

      expect(gate.webTouchUpIsTap(0.5, 0.5), isFalse);
    });

    test('a large WebView delta is a scroll when Flutter saw no pointers', () {
      gate.webTouchDown(0.5, 0.87);
      advance(150);

      expect(gate.webTouchUpIsTap(0.5, 0.4), isFalse);
    });
  });

  group('duplicate events from epubView.js', () {
    test('a touch-up with no live touch-down is ignored', () {
      expect(gate.webTouchUpIsTap(0.5, 0.5), isFalse);
    });

    test('a second touch-up for the same touch does not toggle again', () {
      gate.pointerDown(const Offset(200, 400));
      gate.webTouchDown(0.5, 0.5);
      advance(80);
      gate.pointerUp(const Offset(200, 400));

      expect(gate.webTouchUpIsTap(0.5, 0.5), isTrue);
      expect(gate.webTouchUpIsTap(0.5, 0.5), isFalse);
    });

    test('a duplicate touch-down does not re-anchor a gesture in flight', () {
      gate.webTouchDown(0.5, 0.87);
      advance(150);
      // The same physical touch, reported again by another JS listener. If
      // this re-anchored the gesture, the drag below would look like it
      // started where it ended.
      gate.webTouchDown(0.5, 0.6);
      advance(150);

      expect(gate.webTouchUpIsTap(0.5, 0.4), isFalse);
    });

    test('an abandoned touch-down does not wedge the gate shut', () {
      gate.webTouchDown(0.5, 0.5);
      // Its touch-up never arrived; the next real gesture must still work.
      advance(ReaderTapGate.staleTouchDown.inMilliseconds + 1);
      gate.webTouchDown(0.5, 0.5);
      advance(80);

      expect(gate.webTouchUpIsTap(0.5, 0.5), isTrue);
    });
  });

  test('a stale Flutter measurement is not reused by a later touch', () {
    gate.pointerDown(const Offset(200, 700));
    gate.pointerMove(const Offset(200, 400));
    gate.pointerUp(const Offset(200, 400));
    // Long enough that this drag says nothing about the touch below.
    advance(ReaderTapGate.pointerGestureGrace.inMilliseconds + 100);

    gate.webTouchDown(0.5, 0.5);
    advance(80);

    expect(gate.webTouchUpIsTap(0.5, 0.5), isTrue);
  });

  test('reset clears both streams', () {
    gate.pointerDown(const Offset(200, 400));
    gate.webTouchDown(0.5, 0.5);
    gate.reset();
    advance(80);

    expect(gate.webTouchUpIsTap(0.5, 0.5), isFalse);
  });
}
