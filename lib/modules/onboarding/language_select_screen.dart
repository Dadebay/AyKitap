import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/strings/language_select_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../main_nav/main_nav_screen.dart';
import '../profile/widgets/language_sheet.dart';

/// Shown exactly once, right after [OnboardingScreen] finishes (skip or
/// complete) — before the very first entry into [MainNavScreen]. Picking a
/// language here just calls the same [AppLocale.setLanguage] the Settings
/// screen's [LanguageSheet] uses; there's nothing first-run-specific about
/// the choice itself; only about being asked immediately instead of leaving
/// the default (Turkmen) until the user finds Settings.
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  AppLanguageCode? _selected;

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null) return;
    await AppLocale.instance.setLanguage(selected);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: AppTheme.instance.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LanguageSelectStrings.title,
                style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                LanguageSelectStrings.subtitle,
                style: TextStyle(color: AppColors.grey2, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 32),
              ...kSettingsLanguages.map((lang) {
                final isSelected = lang.code == _selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selected = lang.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          flagFor(lang, size: 34),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              lang.label,
                              style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : AppColors.grey3,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Text(
                    LanguageSelectStrings.continueLabel,
                    style: TextStyle(color: _selected == null ? AppColors.grey3 : Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
