import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/search_strings.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/services/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/phone_login_screen.dart';
import '../../profile/book_request_sheet.dart';

/// What a search that found nothing shows.
///
/// The illustration and "Netije tapylmady" were the whole state before, which
/// is a dead end: the reader has just told us, in their own words, about a
/// book we do not have, and the app's answer was to shrug. The same request
/// the profile's "Kitap haýyşlarym" screen sends ([BookRequestSheet]) is
/// offered right here instead, at the one moment the reader actually wants
/// to send it.
class SearchNoResultsState extends StatelessWidget {
  const SearchNoResultsState({super.key});

  /// The request is posted as the signed-in account (`POST /suggests`), so a
  /// signed-out reader is sent through login first rather than filling the
  /// sheet in and being told 401 by the server afterwards. Same shape as
  /// [LibraryLoginRequiredState]: the login screen can be dismissed by a back
  /// gesture after a successful verify without popping `true`, so the stored
  /// token is what gets trusted, not the pop result.
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
    final isDark = AppTheme.instance.isDark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                isDark ? 'assets/images/search_empty_dark.webp' : 'assets/images/search_empty_light.webp',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            SearchStrings.noResults,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            SearchStrings.noResultsSuggestBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          // Sized to its label rather than full-width: the state is
          // centred in open space, and a button stretched across it would
          // read as the page's primary action instead of an offer.
          FilledButton.icon(
            onPressed: () => _suggest(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: Colors.white, size: 19),
            label: Text(
              SearchStrings.suggestBook,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
