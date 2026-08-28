import 'package:flutter/widgets.dart';
import 'app_orientation_policy.dart';
import 'window_size_class.dart';

/// Feeds [AppOrientationPolicy] the window's current size class — the one
/// spot in the widget tree that reads [WindowSizeClass] purely as a side
/// effect, so the policy always has an up to date width class without every
/// screen that cares about orientation needing to read it itself.
///
/// Sits in `MaterialApp.builder`, above the [Navigator] — a
/// [StatefulWidget] rather than a plain `Builder` so the read happens in
/// `didChangeDependencies`, which Flutter re-runs on its own whenever
/// [MediaQuery] changes (resize, rotation, a fold's posture changing), the
/// same mechanism [State.build] depending on an `InheritedWidget` uses.
class AppOrientationObserver extends StatefulWidget {
  final Widget child;

  const AppOrientationObserver({super.key, required this.child});

  @override
  State<AppOrientationObserver> createState() => _AppOrientationObserverState();
}

class _AppOrientationObserverState extends State<AppOrientationObserver> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppOrientationPolicy.instance.updateWindow(WindowSizeClass.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
