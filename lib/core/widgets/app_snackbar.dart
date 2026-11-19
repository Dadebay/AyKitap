import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Replaces the raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`
/// repeated across 15+ screens with a themed floating pill: a looping book
/// animation for success/info, a red alert glyph for errors. It carries no
/// text of its own beyond [message] — every call site already passes an
/// `AppStrings`-localized string, so there's nothing here that needs its own
/// translation, and [AppColors] makes it follow the light/dark theme like
/// every other widget in the app.
///
/// Drawn straight into the root [Overlay] instead of through a
/// `ScaffoldMessenger`: the app currently mixes `flutter/material` and
/// `material_ui` widgets, whose messengers and scaffolds can't see each
/// other (a `material_ui` messenger found no scaffold to show in, or threw
/// "No ScaffoldMessenger widget found"). An overlay entry needs neither.
extension AppSnackBar on BuildContext {
  void showAppSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.maybeOf(this, rootOverlay: true);
    if (overlay == null) return;
    _AppSnackBarHost.show(overlay, message, isError);
  }
}

class _AppSnackBarHost extends StatefulWidget {
  const _AppSnackBarHost(
      {required this.message, required this.isError, required this.onDone});
  final String message;
  final bool isError;
  final VoidCallback onDone;

  /// The one snack bar on screen — a new one replaces it, like
  /// `hideCurrentSnackBar` + `showSnackBar` did.
  static OverlayEntry? _current;

  static void show(OverlayState overlay, String message, bool isError) {
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppSnackBarHost(
        message: message,
        isError: isError,
        onDone: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  @override
  State<_AppSnackBarHost> createState() => _AppSnackBarHostState();
}

class _AppSnackBarHostState extends State<_AppSnackBarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      // Clears [WheelNavBar]'s dome on the main tabs (which pad their own
      // scroll content by the same ~100 for the same reason) — pushed
      // sub-screens without that bar just get a little extra breathing room.
      bottom: 100 + media.viewPadding.bottom + media.viewInsets.bottom,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _curve,
          child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
                    .animate(_curve),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Material(
                  type: MaterialType.transparency,
                  child: _AppSnackBarCard(
                      message: widget.message, isError: widget.isError),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppSnackBarCard extends StatelessWidget {
  final String message;
  final bool isError;
  const _AppSnackBarCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final accent = isError ? const Color(0xFFE5484D) : AppColors.primary;
    final isDark = AppTheme.instance.isDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        // AppColors.border is too subtle here — it's tuned for cards sitting
        // on the scaffold, but this pill floats over whatever screen content
        // is behind it, which is often the same surface color. A brighter
        // edge (a white glow in dark mode, a harder black shadow in light
        // mode) is what actually separates it from the background.
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10)),
          if (isDark)
            BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: isError
                ? Center(
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancelCircle,
                        color: accent,
                        size: 19))
                // A book "idea" animation reads as a friendly confirmation
                // rather than a generic checkmark — fits a reading app.
                : Lottie.asset('assets/animations/book_idea.json',
                    repeat: true, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
