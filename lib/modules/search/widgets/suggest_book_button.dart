import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/search_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/phone_login_screen.dart';
import '../../profile/book_request_sheet.dart';

/// Shared book-request action for both an empty search and the end of a
/// non-empty result list whose matches may not be the exact requested title.
class SuggestBookButton extends StatelessWidget {
  const SuggestBookButton({super.key});

  /// `POST /suggests` needs an account, so signed-out readers authenticate
  /// before the request sheet opens. The token is authoritative because the
  /// login screen can be dismissed after a successful verification without
  /// returning a navigation result.
  Future<void> _suggest(BuildContext context) async {
    if (!await AuthSession.isLoggedIn()) {
      if (!context.mounted) return;
      await context.push<bool>(const PhoneLoginScreen());
      if (!await AuthSession.isLoggedIn()) return;
    }
    if (!context.mounted) return;
    await BookRequestSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('search-suggest-book-button'),
      onPressed: () => _suggest(context),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedBookOpen01,
        color: Colors.white,
        size: 19,
      ),
      label: Text(
        SearchStrings.suggestBook,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
