import 'package:flutter/widgets.dart';

/// Every spacing value in the app comes from here — screens never hardcode
/// a bare number for padding or gaps between widgets.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// The standard horizontal content padding used across screens.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
}
