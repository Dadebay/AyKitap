import 'package:flutter/widgets.dart';
import 'window_size_class.dart';

/// Keeps the app shell's phone-shaped screens (Home, Library, Profile,
/// Search) at a phone-shaped width when the window is wider than a phone —
/// a tablet, a foldable opened flat or in book posture, a desktop window —
/// rather than stretching cards and rows out to fill however much room
/// happens to be there.
///
/// Every one of those screens was designed and tuned for a phone's ~360-430
/// dp width; there's no wide layout for them (that's WindowSizeClass's other
/// consumer, the EPUB reader's two-page spread, which *does* have one). So
/// instead of building a second layout, this centres the existing one inside
/// a column capped at [maxWidth] and lets the window's own background show
/// on either side, the same way a phone app opened in a resizable desktop
/// window usually behaves.
///
/// Deliberately not applied to the reader routes (EPUB/PDF/CBZ) or to the
/// [WheelNavBar] — see [MainNavScreen], the only place this wraps.
class PhoneSafeCanvas extends StatelessWidget {
  final Widget child;

  /// Comfortably inside the requested 520-600dp range — wide enough that a
  /// two-column card grid still has room to breathe, narrow enough that a
  /// long line of body text doesn't run past a comfortable reading measure.
  static const double maxWidth = 560.0;

  const PhoneSafeCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = WindowSizeClass.of(context).width;
    if (width == WindowWidthClass.compact) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
