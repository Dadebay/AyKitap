import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/account_service.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/strings/settings_strings.dart';
import '../../core/widgets/app_back_button.dart';
import 'widgets/contact_us_sheet.dart';
import 'widgets/language_sheet.dart';
import 'widgets/settings_tiles.dart';

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
  AppLanguage _languageFor(AppLanguageCode code) => kSettingsLanguages.firstWhere((l) => l.code == code);

  // Best-effort: the local session (see [AuthSession]) is what "logged in"
  // actually means to the rest of the app, so a failed/offline logout call
  // must never block clearing it — the caller clears the token regardless.
  Future<void> _notifyBackendLogout() async {
    try {
      await AuthApiService.logout();
    } catch (_) {}
  }

  void _pickLanguage() async {
    final current = _languageFor(AppLocale.instance.current);
    final result = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LanguageSheet(languages: kSettingsLanguages, selected: current),
    );
    if (result != null) await AppLocale.instance.setLanguage(result.code);
  }

  // Same shape as [_confirmDeleteAccount] — a centred icon, title, body, and
  // a stacked primary/cancel action pair — just with the logout icon and the
  // app's own accent colour instead of the destructive red, since leaving a
  // session isn't a destructive action the way deleting the account is.
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedLogout01, color: AppColors.primary, size: 26)),
        ),
        title: Text(
          SettingsStrings.logoutTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          SettingsStrings.logoutBody,
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  onPressed: () async {
                    await _notifyBackendLogout();
                    await AuthSession.clearToken();
                    // Drop the cached /users/me record too, so the next
                    // account doesn't briefly see this one's balance.
                    AccountService.instance.clear();
                    // ...and this one's purchased books, which otherwise
                    // would unlock them for whoever logs in next.
                    await BookAccessService.instance.clear();
                    if (!mounted) return;
                    Navigator.pop(context); // close the dialog
                    Navigator.pop(context, 'logout'); // leave the settings screen logged out
                  },
                  child: Text(SettingsStrings.logoutConfirm, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
                    await _notifyBackendLogout();
                    await AuthSession.clearToken();
                    // Drop the cached /users/me record too, so the next
                    // account doesn't briefly see this one's balance.
                    AccountService.instance.clear();
                    // ...and this one's purchased books, which otherwise
                    // would unlock them for whoever logs in next.
                    await BookAccessService.instance.clear();
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
    final darkTheme = context.watch<AppTheme>().isDark;
    final language = _languageFor(context.watch<AppLocale>().current);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(SettingsStrings.title, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SettingsGroup(children: [
            SwitchTile(
              icon: darkTheme ? HugeIcons.strokeRoundedMoon02 : HugeIcons.strokeRoundedSun03,
              iconColor: darkTheme ? const Color(0xFF8B7BF0) : const Color(0xFFFFB020),
              label: SettingsStrings.theme,
              value: darkTheme ? SettingsStrings.themeDark : SettingsStrings.themeLight,
              switchValue: darkTheme,
              onChanged: (v) => AppTheme.instance.setDark(v),
            ),
            NavTile(
              icon: HugeIcons.strokeRoundedGlobal,
              label: SettingsStrings.language,
              value: language.label,
              leadingValue: flagFor(language, size: 22),
              onTap: _pickLanguage,
            ),
          ]),
          const SizedBox(height: 16),
          SettingsGroup(children: [
            NavTile(icon: HugeIcons.strokeRoundedCustomerService01, label: SettingsStrings.contactUs, value: '', onTap: () => ContactUsSheet.show(context)),
          ]),
          if (widget.isLoggedIn) ...[
            const SizedBox(height: 16),
            SettingsGroup(children: [
              NavTile(
                icon: HugeIcons.strokeRoundedLogout01,
                label: SettingsStrings.logout,
                danger: true,
                onTap: _confirmLogout,
              ),
              NavTile(icon: HugeIcons.strokeRoundedDelete02, label: SettingsStrings.deleteAccount, danger: true, onTap: _confirmDeleteAccount),
            ]),
          ],
          const SizedBox(height: 24),
          Center(child: Text(SettingsStrings.appVersion, style: TextStyle(color: AppColors.grey3, fontSize: 12))),
        ],
        ),
      ),
    );
  }
}
