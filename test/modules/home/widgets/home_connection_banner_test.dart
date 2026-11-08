import 'dart:async';

import 'package:aykitap/modules/home/widgets/home_connection_banner.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [ConnectivityPlatform] the test drives directly, standing in for the
/// real platform channel `Connectivity()` would otherwise reach for.
class _FakeConnectivityPlatform extends ConnectivityPlatform {
  List<ConnectivityResult> checkResult = [ConnectivityResult.wifi];
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => checkResult;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> result) => _controller.add(result);

  void dispose() => _controller.close();
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// The Scaffold itself already contributes a [Material], so presence is
/// checked by the banner's own icon rather than `find.byType(Material)`.
Finder get _anyBannerIcon => find.byWidgetPredicate((w) =>
    w is Icon &&
    (w.icon == Icons.cloud_off_rounded || w.icon == Icons.cloud_done_rounded));

void main() {
  late _FakeConnectivityPlatform fake;

  setUp(() {
    fake = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fake;
  });

  tearDown(() => fake.dispose());

  testWidgets('already online at cold start shows no banner', (tester) async {
    fake.checkResult = [ConnectivityResult.wifi];
    await tester
        .pumpWidget(_app(HomeConnectionBanner(onReconnected: () async {})));
    await tester.pump();
    await tester.pump();

    expect(_anyBannerIcon, findsNothing);
  });

  testWidgets('going offline slides and fades the offline banner in',
      (tester) async {
    fake.checkResult = [ConnectivityResult.wifi];
    await tester
        .pumpWidget(_app(HomeConnectionBanner(onReconnected: () async {})));
    await tester.pump();
    await tester.pump();

    fake.emit([ConnectivityResult.none]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-transition — neither fully hidden nor fully settled yet. More
    // than one FadeTransition wraps the incoming icon (ours, plus
    // AnimatedSwitcher's own crossfade machinery), so this checks that at
    // least one of them is genuinely mid-flight rather than picking one
    // arbitrarily.
    final fades = tester
        .widgetList<FadeTransition>(find.ancestor(
            of: find.byIcon(Icons.cloud_off_rounded),
            matching: find.byType(FadeTransition)))
        .toList();
    expect(
        fades.any((f) => f.opacity.value > 0 && f.opacity.value < 1), isTrue);

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets(
      'reconnecting shows the green restored state, refreshes Home, then auto-hides',
      (tester) async {
    fake.checkResult = [ConnectivityResult.none];
    var reconnectedCalls = 0;
    await tester.pumpWidget(_app(HomeConnectionBanner(
      onReconnected: () async => reconnectedCalls++,
    )));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

    fake.emit([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    expect(reconnectedCalls, 1);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(_anyBannerIcon, findsNothing);
  });

  testWidgets(
      'a repeated identical online event does not stack a second banner',
      (tester) async {
    fake.checkResult = [ConnectivityResult.none];
    await tester
        .pumpWidget(_app(HomeConnectionBanner(onReconnected: () async {})));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    fake.emit([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pumpAndSettle();
    fake.emit([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
  });
}
