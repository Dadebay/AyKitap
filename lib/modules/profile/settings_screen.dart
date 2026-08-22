import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/services/account_service.dart';
import '../../core/services/book_access_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/strings/settings_strings.dart';
import '../../core/widgets/app_back_button.dart';
import 'widgets/contact_us_sheet.dart';
import 'widgets/language_sheet.dart';
import 'widgets/settings_confirm_dialog.dart';
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
  AppLanguage _languageFor(AppLanguageCode code) =>
      kSettingsLanguages.firstWhere((l) => l.code == code);

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
      builder: (_) =>
          LanguageSheet(languages: kSettingsLanguages, selected: current),
    );
    if (result != null) await AppLocale.instance.setLanguage(result.code);
  }

  // Both dialogs below end in the exact same place: neither actually calls
  // a distinct "delete account" API today, they just clear the local
  // session — see [showSettingsConfirmDialog]'s call sites. Preserved as-is
  // rather than changed, since fixing that is a behaviour change outside
  // this refactor's scope.
  Future<void> _clearSessionAndClose() async {
    await _notifyBackendLogout();
    await AuthSession.clearToken();
    // Drop the cached /users/me record too, so the next account doesn't
    // briefly see this one's balance.
    AccountService.instance.clear();
    // ...and this one's purchased books, which otherwise would unlock them
    // for whoever logs in next.
    await BookAccessService.instance.clear();
    await SubscriptionService.instance.clear();
    if (!mounted) return;
    Navigator.pop(context); // close the dialog
    Navigator.pop(context, 'logout'); // leave the settings screen logged out
  }

  void _confirmLogout() {
    showSettingsConfirmDialog(
      context,
      icon: HugeIcon(
          icon: HugeIcons.strokeRoundedLogout01,
          color: AppColors.primary,
          size: 26),
      iconSize: 56,
      iconColor: AppColors.primary,
      title: SettingsStrings.logoutTitle,
      body: SettingsStrings.logoutBody,
      confirmLabel: SettingsStrings.logoutConfirm,
      confirmColor: AppColors.primary,
      onConfirm: _clearSessionAndClose,
    );
  }

  void _confirmDeleteAccount() {
    showSettingsConfirmDialog(
      context,
      icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: Colors.redAccent,
          size: 24),
      iconSize: 52,
      iconColor: Colors.redAccent,
      title: SettingsStrings.deleteAccountTitle,
      body: SettingsStrings.deleteAccountBody,
      confirmLabel: SettingsStrings.delete,
      confirmColor: Colors.redAccent,
      onConfirm: _clearSessionAndClose,
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
        title: Text(SettingsStrings.title,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsGroup(children: [
              SwitchTile(
                icon: darkTheme
                    ? HugeIcons.strokeRoundedMoon02
                    : HugeIcons.strokeRoundedSun03,
                iconColor: darkTheme
                    ? const Color(0xFF8B7BF0)
                    : const Color(0xFFFFB020),
                label: SettingsStrings.theme,
                value: darkTheme
                    ? SettingsStrings.themeDark
                    : SettingsStrings.themeLight,
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
              NavTile(
                  icon: HugeIcons.strokeRoundedCustomerService01,
                  label: SettingsStrings.contactUs,
                  value: '',
                  onTap: () => ContactUsSheet.show(context)),
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
                NavTile(
                    icon: HugeIcons.strokeRoundedDelete02,
                    label: SettingsStrings.deleteAccount,
                    danger: true,
                    onTap: _confirmDeleteAccount),
              ]),
            ],
            const SizedBox(height: 24),
            Center(
                child: Text(SettingsStrings.appVersion,
                    style: TextStyle(color: AppColors.grey3, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
