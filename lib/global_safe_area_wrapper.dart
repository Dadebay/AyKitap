import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalSafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const GlobalSafeAreaWrapper({
    super.key,
    required this.child,
    this.top = false,
    // Every screen already manages its own bottom inset (WheelNavBar,
    // sticky CTAs, etc. all read MediaQuery.padding.bottom themselves), so
    // padding it again here left an extra strip of unpainted (black) space
    // in the iPhone home-indicator area.
    this.bottom = false,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _getSystemUiOverlayStyle(context),
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      ),
    );
  }

  SystemUiOverlayStyle _getSystemUiOverlayStyle(BuildContext context) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
