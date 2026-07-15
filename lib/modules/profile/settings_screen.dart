import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/auth_session.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/strings/settings_strings.dart';

class _AppLanguage {
  final AppLanguageCode code;
  final String label;
  final String? flagAsset; // null when no flag artwork is available yet
  const _AppLanguage(this.code, this.label, this.flagAsset);
}

/// Sazlamalar — TZ 8.6.
/// The "Çykmak" / "Hasaby poz" group only makes sense for a signed-in
/// user (it needs a session to end or an account to delete), so it's
/// hidden entirely when [isLoggedIn] is false.
class SettingsScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SettingsScreen({super.key, this.isLoggedIn = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get _darkTheme => AppTheme.instance.isDark;
  _AppLanguage get _language => _languages.firstWhere((l) => l.code == AppLocale.instance.current);

  @override
  void initState() {
    super.initState();
    AppTheme.instance.addListener(_onChanged);
    AppLocale.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    AppTheme.instance.removeListener(_onChanged);
    AppLocale.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  static const _languages = [
    _AppLanguage(AppLanguageCode.tk, SettingsStrings.langTurkmen, 'assets/flags/tm.svg'),
    _AppLanguage(AppLanguageCode.ru, SettingsStrings.langRussian, 'assets/flags/ru.svg'),
    _AppLanguage(AppLanguageCode.tr, SettingsStrings.langTurkish, 'assets/flags/tr.svg'),
  ];

  Widget _flagFor(_AppLanguage lang, {double size = 28}) {
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

  void _pickLanguage() async {
    final result = await showModalBottomSheet<_AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(
        languages: _languages,
        selected: _language,
        flagBuilder: _flagFor,
      ),
    );
    if (result != null) await AppLocale.instance.setLanguage(result.code);
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.redAccent, size: 24)),
        ),
        title: Text(
          SettingsStrings.deleteAccountTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          SettingsStrings.deleteAccountBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  onPressed: () async {
                    await AuthSession.clearToken();
                    if (!mounted) return;
                    Navigator.pop(context); // close the dialog
                    Navigator.pop(context, 'logout'); // leave the settings screen logged out
                  },
                  child: Text(SettingsStrings.delete, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(SettingsStrings.cancel, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(SettingsStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsGroup(children: [
            _SwitchTile(
              icon: _darkTheme ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun03,
              iconColor: _darkTheme ? const Color(0xFF8B7BF0) : const Color(0xFFFFB020),
              label: SettingsStrings.theme,
              value: _darkTheme ? SettingsStrings.themeDark : SettingsStrings.themeLight,
              switchValue: _darkTheme,
              onChanged: (v) => AppTheme.instance.setDark(v),
            ),
            _NavTile(
              icon: HugeIcons.strokeRoundedGlobal,
              label: SettingsStrings.language,
              value: _language.label,
              leadingValue: _flagFor(_language, size: 22),
              onTap: _pickLanguage,
            ),
          ]),
          const SizedBox(height: 16),
          _SettingsGroup(children: [
            _NavTile(icon: HugeIcons.strokeRoundedCustomerService01, label: SettingsStrings.contactUs, value: '', onTap: () {}),
          ]),
          if (widget.isLoggedIn) ...[
            const SizedBox(height: 16),
            _SettingsGroup(children: [
              _NavTile(
                icon: HugeIcons.strokeRoundedLogout01,
                label: SettingsStrings.logout,
                danger: true,
                onTap: () async {
                  await AuthSession.clearToken();
                  if (!mounted) return;
                  Navigator.pop(context, 'logout');
                },
              ),
              _NavTile(icon: HugeIcons.strokeRoundedDelete02, label: SettingsStrings.deleteAccount, danger: true, onTap: _confirmDeleteAccount),
            ]),
          ],
          const SizedBox(height: 24),
          Center(child: Text(SettingsStrings.appVersion, style: TextStyle(color: AppColors.grey3, fontSize: 12))),
        ],
      ),
    );
  }
}

/// Dil saýlamak bottom sheet — redesigned with a drag handle, a title, and
/// flag-led rows so the current language is easy to scan at a glance.
class _LanguageSheet extends StatelessWidget {
  final List<_AppLanguage> languages;
  final _AppLanguage selected;
  final Widget Function(_AppLanguage, {double size}) flagBuilder;

  const _LanguageSheet({required this.languages, required this.selected, required this.flagBuilder});

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
                      flagBuilder(lang, size: 30),
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

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _NavTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? value;
  final Widget? leadingValue;
  final bool danger;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, this.value, this.leadingValue, this.danger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: HugeIcon(icon: icon, color: color, size: 20),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: danger ? Colors.redAccent : AppColors.grey1, fontSize: 14.5, fontWeight: FontWeight.w600)),
      trailing: value != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              if (leadingValue != null) ...[leadingValue!, const SizedBox(width: 8)],
              Text(value!, style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              const SizedBox(width: 6),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 16),
            ])
          : null,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool switchValue;
  final ValueChanged<bool> onChanged;
  _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.switchValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: iconColor, size: 22),
      title: Text(label, style: TextStyle(color: AppColors.grey1, fontSize: 14.5, fontWeight: FontWeight.w600)),
      trailing: _ThemeSwitch(isDark: switchValue, onChanged: onChanged),
      subtitle: Text(value, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
    );
  }
}

/// A pill-shaped toggle with a sun/moon glyph riding inside the thumb,
/// instead of a generic Material [Switch] — reads at a glance which mode
/// is active without needing the subtitle text.
class _ThemeSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ThemeSwitch({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 54,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark ? const [Color(0xFF352E5C), Color(0xFF201A38)] : const [Color(0xFFFFD27A), Color(0xFFFFA726)],
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: HugeIcon(
                icon: isDark ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun03,
                color: isDark ? const Color(0xFF8B7BF0) : const Color(0xFFFFA726),
                size: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
