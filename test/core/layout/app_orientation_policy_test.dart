import 'package:aykitap/core/layout/app_orientation_policy.dart';
import 'package:aykitap/core/layout/window_size_class.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The orientation rule itself, without a platform channel — see
/// [resolveAllowedOrientations].
void main() {
  List<DeviceOrientation> resolve({
    WindowWidthClass width = WindowWidthClass.compact,
    bool reader = false,
    bool forcesLandscape = false,
  }) =>
      resolveAllowedOrientations(
        windowWidth: width,
        readerActive: reader,
        readerForcesLandscape: forcesLandscape,
      );

  test('a phone outside the reader is portrait-only', () {
    expect(resolve(), const [DeviceOrientation.portraitUp]);
  });

  test('a phone in the reader may rotate, but is not made to', () {
    expect(
      resolve(reader: true),
      const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  });

  test('"ýatyk okamak" drops portrait, so rotation lock cannot override it',
      () {
    final allowed = resolve(reader: true, forcesLandscape: true);
    // The point of the setting: merely *allowing* landscape leaves a phone
    // with the system rotation lock on stuck in portrait. Only removing
    // portrait actually turns it.
    expect(allowed, isNot(contains(DeviceOrientation.portraitUp)));
    expect(
      allowed,
      const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
    );
  });

  test('"ýatyk okamak" is ignored once the reader closes', () {
    expect(
        resolve(forcesLandscape: true), const [DeviceOrientation.portraitUp]);
  });

  for (final width in [WindowWidthClass.medium, WindowWidthClass.expanded]) {
    test('a $width window is not locked on its own', () {
      // An empty list means "no preference" — a tablet/foldable/desktop
      // window is already whatever shape its owner made it.
      expect(resolve(width: width), isEmpty);
      expect(resolve(width: width, reader: true), isEmpty);
    });

    test('"ýatyk okamak" still holds on a $width window', () {
      // The flip-flop regression: turning a phone sideways widens the window
      // past the compact breakpoint, so the forced set has to survive the
      // width it just caused. If this returned "no preference", the device
      // would fall back to portrait, the window would read compact again,
      // landscape would be forced again — the phone rocking between the two
      // instead of settling, which is exactly what it did.
      expect(
        resolve(width: width, reader: true, forcesLandscape: true),
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
    });
  }

  test('forcing landscape is stable: applying it again changes nothing', () {
    // One round of the loop, spelled out: force landscape, let the window
    // become wide because the phone obeyed, and re-resolve. A stable rule
    // gives the same answer both times.
    const forced = [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
    expect(resolve(reader: true, forcesLandscape: true), forced);
    expect(
      resolve(
          width: WindowWidthClass.expanded,
          reader: true,
          forcesLandscape: true),
      forced,
    );
  });
}
