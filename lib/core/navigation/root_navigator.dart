import 'package:flutter/material.dart';

/// Lets services outside the widget tree (e.g. [IncomingFileService],
/// reacting to a native "Open with" callback) push a screen without a
/// [BuildContext] of their own. Attached to [MaterialApp.navigatorKey] in
/// main.dart.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
