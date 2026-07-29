import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// Replaces the raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`
/// repeated across 15+ screens with a themed floating pill: a looping book
/// animation for success/info, a red alert glyph for errors. It carries no
/// text of its own beyond [message] — every call site already passes an
/// `AppStrings`-localized string, so there's nothing here that needs its own
/// translation, and [AppColors] makes it follow the light/dark theme like
/// every other widget in the app.
extension AppSnackBar on BuildContext {
  void showAppSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        // Bottom margin clears [WheelNavBar]'s dome on the main tabs (which
        // pad their own scroll content by the same ~100 for the same
        // reason) — pushed sub-screens without that bar just get a little
        // extra breathing room above the edge.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        padding: EdgeInsets.zero,
        content: _AppSnackBarCard(message: message, isError: isError),
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
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.22), blurRadius: 20, offset: const Offset(0, 10)),
          if (isDark) BoxShadow(color: Colors.white.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: isError
                ? Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCancelCircle, color: accent, size: 19))
                // A book "idea" animation reads as a friendly confirmation
                // rather than a generic checkmark — fits a reading app.
                : Lottie.asset('assets/animations/book_idea.json', repeat: true, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.white, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
