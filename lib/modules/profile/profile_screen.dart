import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/gift_strings.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_config.dart';
import '../../core/services/account_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/streak_flame.dart';
import '../../core/widgets/streak_week_row.dart';
import '../auth/phone_login_screen.dart';
import '../payment/subscription_screen.dart';
import '../streak/streak_screen.dart';
import 'balance_screen.dart';
import 'book_suggestions_screen.dart';
import 'edit_profile_screen.dart';
import 'notes_screen.dart';
import 'report_problem_sheet.dart';
import 'settings_screen.dart';
import 'widgets/profile_entry_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/send_gift_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _phone = '';
  String _name = ProfileStrings.defaultReaderName;
  int _avatarIndex = -1;
  String? _avatarImage;
  // Backend-sourced (`/users/me`) — null until a sync succeeds at least
  // once, so the UI falls back to the local/mock values below until then.
  String? _backendAvatarUrl;

  @override
  void initState() {
    super.initState();
    _refreshSession();
    StreakService.instance.load();
    SubscriptionService.instance.load();
  }

  // The bearer token in secure storage is the single source of truth for
  // "logged in" — re-read it instead of trusting whatever this widget's
  // in-memory state happened to be (it wouldn't survive an app restart).
  Future<void> _refreshSession() async {
    final loggedIn = await AuthSession.isLoggedIn();
    final phone = await AuthSession.getPhone();
    final name = await AuthSession.getName();
    final avatar = await AuthSession.getAvatar();
    final avatarImage = await AuthSession.getAvatarImage();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _phone = phone ?? '';
        _name = (name != null && name.isNotEmpty)
            ? name
            : ProfileStrings.defaultReaderName;
        _avatarIndex = avatar;
        _avatarImage = avatarImage;
      });
    }
    if (loggedIn) unawaited(_syncFromBackend());
  }

  // Best-effort only: the locally cached values (read above) are already
  // what the rest of the app renders off of, so a `/users/me` failure here
  // (offline, expired token, ...) is silently ignored rather than surfaced —
  // this just keeps name/phone/avatar/balance fresh when the backend has a
  // newer copy (e.g. edited from another device).
  //
  // Routed through [AccountService] rather than calling [AuthApiService]
  // directly so the balance this screen shows is the same cached record the
  // rest of the app spends from, refreshed by one request instead of two.
  Future<void> _syncFromBackend() async {
    await AccountService.instance.refresh();
    final user = AccountService.instance.user;
    if (user == null) return; // Offline — keep the locally cached values.
    final username = user.username;
    if (username != null && username.isNotEmpty && username != _name) {
      await AuthSession.saveName(username);
    }
    if (!mounted) return;
    setState(() {
      if (username != null && username.isNotEmpty) _name = username;
      if (user.phone.isNotEmpty) _phone = user.phone;
      _backendAvatarUrl = (user.image != null && user.image!.isNotEmpty)
          ? ApiConfig.resolveImageUrl(user.image!)
          : null;
    });
  }

  Future<void> _openBalance() async {
    await context.push(const BalanceScreen());
  }

  Future<void> _openSendGift() async {
    // The sheet awaits AccountService.refresh after a confirmed transfer.
    // This screen watches that service, so the profile balance card rebuilds
    // with the new value as soon as the success dialog is dismissed.
    await SendGiftSheet.show(context);
  }

  // TZ 8.1: phone shown half-hidden as "+993 XX ***XX". Works off the digits
  // so it's robust to whatever spacing the stored value happens to have.
  String get _maskedPhone {
    final digits = _phone.replaceAll(RegExp(r'\D'), '');
    // Strip the 993 country code if present, leaving the 8-digit local number.
    final local = digits.startsWith('993') ? digits.substring(3) : digits;
    if (local.length < 4) return _phone;
    final first = local.substring(0, 2);
    final last = local.substring(local.length - 2);
    return '+993 $first ***$last';
  }

  Future<void> _openEditProfile() async {
    final result = await context.push<bool>(const EditProfileScreen());
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _startLogin() async {
    final result = await context.push<bool>(const PhoneLoginScreen());
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _openSettings() async {
    final result =
        await context.push<String>(SettingsScreen(isLoggedIn: _isLoggedIn));
    if (result == 'logout' && mounted) {
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AccountService>().balanceManat;
    final subscription = context.watch<SubscriptionService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text(ProfileStrings.profileTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Extra bottom padding so the last card clears the floating nav
          // bar's dome — otherwise its solid card color shows through
          // behind the bar, unlike the plain background on other tabs.
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: _isLoggedIn
              ? [
                  ProfileTopSection(
                      name: _name,
                      maskedPhone: _maskedPhone,
                      avatarIndex: _avatarIndex,
                      avatarImage: _avatarImage,
                      avatarUrl: _backendAvatarUrl,
                      onTap: _openEditProfile),
                  const SizedBox(height: 24),
                  _buildBalanceEntry(context, balance),
                  const SizedBox(height: 12),
                  _buildSendGiftButton(context),
                  const SizedBox(height: 12),
                  _buildSubscriptionEntry(context, subscription),
                  const SizedBox(height: 12),
                  _buildStreakSection(context),
                  const SizedBox(height: 12),
                  _buildSettingsEntry(context),
                  const SizedBox(height: 12),
                  _buildNotesButton(context),
                  const SizedBox(height: 12),
                  _buildBookRequestButton(context),
                  const SizedBox(height: 12),
                  _buildReportProblemButton(context),
                ]
              : [
                  LoggedOutSection(onLogin: _startLogin),
                  const SizedBox(height: 24),
                  _buildSettingsEntry(context),
                ],
        ),
      ),
    );
  }

  Widget _buildBalanceEntry(BuildContext context, int? balance) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedWallet01),
      title: ProfileStrings.balanceTitle,
      subtitle: balance != null ? PaymentStrings.manat(balance) : null,
      onTap: _openBalance,
    );
  }

  Widget _buildSendGiftButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedGift),
      title: GiftStrings.entryTitle,
      onTap: _openSendGift,
    );
  }

  // Highlighted (primary tint + border, same treatment as the book-request
  // CTA below) and shows the real expiry when active, rather than the always-
  // -on "Abuna ýazyl" subtitle — so an active subscription is obvious right
  // on this row, without opening SubscriptionScreen to check.
  Widget _buildSubscriptionEntry(
      BuildContext context, SubscriptionService subscription) {
    final active = subscription.isActive;
    final expiresAt = subscription.expiresAt;
    return ProfileEntryCard(
      leading: profileIconCircle(active
          ? HugeIcons.strokeRoundedCheckmarkCircle01
          : HugeIcons.strokeRoundedDiamond),
      title: ProfileStrings.subscription,
      subtitle: active && expiresAt != null
          ? ProfileStrings.subscriptionActiveUntil(
              DateFormat.yMMMd().format(expiresAt))
          : ProfileStrings.subscribeNow,
      highlighted: active,
      onTap: () => context.push(const SubscriptionScreen()),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    // Watched here rather than off the singleton (with a bare
    // `context.watch<StreakService>()` up in build standing in for it): this
    // is the only thing on the screen that reads the streak, so keeping the
    // subscription next to the values it feeds means neither can be moved
    // or removed without the other.
    final streak = context.watch<StreakService>();
    return ProfileEntryCard(
      leading:
          const SizedBox(width: 40, height: 40, child: StreakFlame(size: 32)),
      title: ProfileStrings.streakDays(streak.currentStreak),
      subtitle: ProfileStrings.bestStreak(streak.bestStreak),
      extra: StreakWeekRow(weekRead: streak.weekRead, circleSize: 34),
      onTap: () => context.push(const StreakScreen()),
    );
  }

  Widget _buildSettingsEntry(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedSettings01),
      title: ProfileStrings.settingsEntryTitle,
      onTap: _openSettings,
    );
  }

  Widget _buildNotesButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedNote01),
      title: ProfileStrings.viewAllNotes,
      onTap: () => context.push(const NotesScreen()),
    );
  }

  Widget _buildBookRequestButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBookOpen01),
      title: ProfileStrings.sendBookRequest,
      highlighted: true,
      onTap: () => context.push(const BookSuggestionsScreen()),
    );
  }

  Widget _buildReportProblemButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBug01),
      title: ProfileStrings.reportProblemEntryTitle,
      onTap: () => ReportProblemSheet.show(context),
    );
  }
}
