import 'package:flutter/material.dart';
import '../../../core/localization/strings/library_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/account_service.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/services/book_access_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/phone_login_screen.dart';

class LibraryEmptyState extends StatelessWidget {
  final String label;
  final String? sub;
  const LibraryEmptyState({super.key, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark ? 'assets/images/library_empty_dark.webp' : 'assets/images/library_empty_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(sub!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey3, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown instead of [LibraryEmptyState] on any [LibraryScreen] tab whose
/// fetch came back 401 — a signed-out visitor gets a reason and a way out
/// instead of the raw "Authentication required" server message.
class LibraryLoginRequiredState extends StatelessWidget {
  /// Called after a successful login so the tab can re-fetch immediately
  /// instead of waiting for the next pull-to-refresh.
  final VoidCallback? onLoggedIn;

  const LibraryLoginRequiredState({super.key, this.onLoggedIn});

  /// Same "push login, trust the stored token over the pop result, refresh
  /// what a fresh session changes" shape as [BookOpenFlow]'s login step —
  /// the login screen can be dismissed by a back gesture after a successful
  /// verify without popping `true`.
  Future<void> _login(BuildContext context) async {
    await context.push<bool>(const PhoneLoginScreen());
    if (!await AuthSession.isLoggedIn()) return;
    await AccountService.instance.refresh();
    await BookAccessService.instance.refreshPurchased();
    onLoggedIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  isDark ? 'assets/images/library_empty_dark.webp' : 'assets/images/library_empty_light.webp',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LibraryStrings.loginRequiredTitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              LibraryStrings.loginRequiredSub,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey3, fontSize: 13),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: ProfileStrings.login,
              height: 48,
              onPressed: () => _login(context),
            ),
          ],
        ),
      ),
    );
  }
}
