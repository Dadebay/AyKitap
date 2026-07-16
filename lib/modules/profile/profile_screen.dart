import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/streak_flame.dart';
import '../../core/widgets/streak_week_row.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../auth/phone_login_screen.dart';
import '../payment/subscription_screen.dart';
import '../streak/streak_screen.dart';
import 'bookmarks_screen.dart';
import 'notes_screen.dart';
import 'book_request_sheet.dart';
import 'edit_profile_screen.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';
import 'widgets/profile_entry_card.dart';
import 'widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _hasSubscription = false;

  bool _isLoggedIn = false;
  String _phone = '';
  String _name = ProfileStrings.defaultReaderName;
  int _avatarIndex = -1;
  String? _avatarImage;

  @override
  void initState() {
    super.initState();
    _refreshSession();
    StreakService.instance.load();
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
        _name = (name != null && name.isNotEmpty) ? name : ProfileStrings.defaultReaderName;
        _avatarIndex = avatar;
        _avatarImage = avatarImage;
      });
    }
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
    final result = await context.push<String>(SettingsScreen(isLoggedIn: _isLoggedIn));
    if (result == 'logout' && mounted) {
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<StreakService>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text(ProfileStrings.profileTitle, style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w700)),
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
                  ProfileTopSection(name: _name, maskedPhone: _maskedPhone, avatarIndex: _avatarIndex, avatarImage: _avatarImage, onTap: _openEditProfile),
                  const SizedBox(height: 24),
                  _buildSubscriptionEntry(context),
                  const SizedBox(height: 12),
                  _buildStreakSection(context),
                  const SizedBox(height: 12),
                  _buildFinanceEntry(context),
                  const SizedBox(height: 12),
                  _buildSettingsEntry(context),
                  const SizedBox(height: 12),
                  _buildNotesSection(context),
                  _buildBookmarksSection(context),
                  const SizedBox(height: 12),
                  _buildBookRequestButton(context),
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

  Widget _buildSubscriptionEntry(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedDiamond),
      title: ProfileStrings.subscription,
      subtitle: _hasSubscription ? ProfileStrings.daysLeft : ProfileStrings.subscribeNow,
      onTap: () => context.push(const SubscriptionScreen()),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return ProfileEntryCard(
      leading: const SizedBox(width: 40, height: 40, child: StreakFlame(size: 32)),
      title: ProfileStrings.streakDays(StreakService.instance.currentStreak),
      subtitle: ProfileStrings.bestStreak(StreakService.instance.bestStreak),
      extra: StreakWeekRow(weekRead: StreakService.instance.weekRead, circleSize: 34),
      onTap: () => context.push(const StreakScreen()),
    );
  }

  Widget _buildFinanceEntry(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedWallet01),
      title: ProfileStrings.finance,
      subtitle: ProfileStrings.balanceManat(StreakService.instance.balanceManat),
      onTap: () => context.push(const FinanceScreen()),
    );
  }

  Widget _buildSettingsEntry(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedSettings01),
      title: ProfileStrings.settingsEntryTitle,
      onTap: _openSettings,
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedNote01),
      title: ProfileStrings.viewAllNotes,
      onTap: () => context.push(const NotesScreen()),
    );
  }

  Widget _buildBookmarksSection(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBookmark01),
      title: ProfileStrings.viewAllBookmarks,
      onTap: () => context.push(const BookmarksScreen()),
    );
  }

  Widget _buildBookRequestButton(BuildContext context) {
    return ProfileEntryCard(
      leading: profileIconCircle(HugeIcons.strokeRoundedBookOpen01),
      title: ProfileStrings.sendBookRequest,
      highlighted: true,
      onTap: () => BookRequestSheet.show(context),
    );
  }
}
