import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

/// The plain back-arrow `IconButton` repeated at the top of 15+ screens.
/// Defaults to `Navigator.pop`; pass [onPressed] to override (e.g. to pop
/// with a result).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.size = 22});

  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Most call sites pass a `const AppBackButton(...)` — Flutter then skips
    // rebuilding this widget entirely on a parent rebuild (it sees the same
    // canonicalized instance and short-circuits), so a bare `AppColors.white`
    // read here would freeze at whichever theme was active when this const
    // instance first mounted. Toggling the theme on Settings while it's
    // still on screen left the button stuck at the old colour until leaving
    // and re-entering remounted it fresh. Listening to [AppTheme] directly
    // makes this rebuild on its own regardless of the const-ness of the
    // widget wrapping it.
    return ListenableBuilder(
      listenable: AppTheme.instance,
      builder: (context, _) => IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.white,
            size: size),
      ),
    );
  }
}
