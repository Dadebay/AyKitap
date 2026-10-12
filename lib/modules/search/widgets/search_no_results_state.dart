import 'package:flutter/material.dart';

import '../../../core/localization/strings/search_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import 'suggest_book_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.instance.isDark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SuggestBookButton(),
        ],
      ),
    );
  }
}
