import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/settings_strings.dart';

class AppLanguage {
  final AppLanguageCode code;
  final String label;
  final String? flagAsset; // null when no flag artwork is available yet
  const AppLanguage(this.code, this.label, this.flagAsset);
}

const kSettingsLanguages = [
  AppLanguage(AppLanguageCode.tk, SettingsStrings.langTurkmen, 'assets/flags/tm.svg'),
  AppLanguage(AppLanguageCode.ru, SettingsStrings.langRussian, 'assets/flags/ru.svg'),
  AppLanguage(AppLanguageCode.tr, SettingsStrings.langTurkish, 'assets/flags/tr.svg'),
];

Widget flagFor(AppLanguage lang, {double size = 28}) {
  final d = size;
  if (lang.flagAsset == null) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedGlobal, color: AppColors.grey2, size: d * 0.6)),
    );
  }
  return ClipOval(
    child: SizedBox(
      width: d,
      height: d,
      child: SvgPicture.asset(lang.flagAsset!, fit: BoxFit.cover),
    ),
  );
}

/// Dil saýlamak bottom sheet — redesigned with a drag handle, a title, and
/// flag-led rows so the current language is easy to scan at a glance.
class LanguageSheet extends StatelessWidget {
  final List<AppLanguage> languages;
  final AppLanguage selected;

  const LanguageSheet({super.key, required this.languages, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(SettingsStrings.chooseLanguage, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            ...languages.map((lang) {
              final isSelected = lang.label == selected.label;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(context, lang),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.4)) : null,
                  ),
                  child: Row(
                    children: [
                      flagFor(lang, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(color: AppColors.white, fontSize: 15.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                      HugeIcon(
                        icon: isSelected ? HugeIcons.strokeRoundedCheckmarkCircle01 : HugeIcons.strokeRoundedCircle,
                        color: isSelected ? AppColors.primary : AppColors.grey3,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
