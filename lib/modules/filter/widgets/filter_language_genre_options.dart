import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/filter_strings.dart';
import '../controller/filter_controller.dart';
import 'filter_chips.dart';

/// The "Dil" section's body — the chips come from `GET /book-languages`, so
/// it also has to render the load's in-flight and failed states. Used by
/// [FilterQuickSections].
class LanguageOptions extends StatelessWidget {
  final FilterController c;
  const LanguageOptions(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final languages = c.languages;
    if (languages == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }
    if (languages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                c.languagesFailed
                    ? FilterStrings.langLoadFailed
                    : FilterStrings.any,
                style: TextStyle(color: AppColors.grey2, fontSize: 13.5),
              ),
            ),
            if (c.languagesFailed)
              TextButton(
                onPressed: c.loadLanguages,
                child: Text(FilterStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages
          .map((l) => MultiChip(
                label: l.label,
                selected: c.selectedLanguageIds.contains(l.id),
                onTap: () => c.toggleLanguage(l),
              ))
          .toList(),
    );
  }
}

/// The "Žanr" section's body — same shape as "Dil", one chip row sourced
/// from `GET /genres/all`. Single-select: picking one here is the same
/// [FilterController.selectedGenreId] Search's own chip row highlights. Used
/// by [FilterQuickSections].
class GenreOptions extends StatelessWidget {
  final FilterController c;
  const GenreOptions(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final genres = c.genres;
    if (genres == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }
    if (genres.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                c.genresFailed
                    ? FilterStrings.genreLoadFailed
                    : FilterStrings.any,
                style: TextStyle(color: AppColors.grey2, fontSize: 13.5),
              ),
            ),
            if (c.genresFailed)
              TextButton(
                onPressed: c.loadGenres,
                child: Text(FilterStrings.retry,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
              ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres
          .map((g) => MultiChip(
                label: g.name,
                selected: c.selectedGenreId == g.id,
                onTap: () => c.toggleGenre(g),
              ))
          .toList(),
    );
  }
}
