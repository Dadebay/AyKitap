import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/streak_service.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/streak_flame.dart';
import '../../core/widgets/streak_week_row.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../auth/phone_login_screen.dart';
import '../payment/subscription_screen.dart';
import '../streak/streak_screen.dart';
import 'notes_screen.dart';
import 'book_request_sheet.dart';
import 'edit_profile_screen.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';

/// A tinted circular icon badge, used as the leading visual on every
/// profile entry card so they all read as one family.
Widget _iconCircle(List<List<dynamic>> icon, {Color? color}) {
  final c = color ?? AppColors.primary;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
    child: Center(child: HugeIcon(icon: icon, color: c, size: 20)),
  );
}

/// Shared shell for every row on the Profile tab (subscription, streak,
/// finance, settings, notes, book request) so they share one padding,
/// radius, and title/subtitle typography instead of each drifting apart.
class _ProfileEntryCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final bool highlighted;
  final VoidCallback onTap;

  const _ProfileEntryCard({
    required this.leading,
    required this.title,
    this.subtitle,
    this.extra,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = highlighted ? AppColors.primary : AppColors.grey1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: highlighted ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: titleColor, fontSize: 14.5, fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: TextStyle(color: AppColors.grey2, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: highlighted ? AppColors.primary : AppColors.grey3, size: 18),
              ],
            ),
            if (extra != null) ...[
              const SizedBox(height: 14),
              extra!,
            ],
          ],
        ),
      ),
    );
  }
}

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
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _startLogin() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(isLoggedIn: _isLoggedIn)),
    );
    if (result == 'logout' && mounted) {
      setState(() => _isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: ListenableBuilder(
          listenable: StreakService.instance,
          builder: (context, _) => ListView(
            // Extra bottom padding so the last card clears the floating nav
            // bar's dome — otherwise its solid card color shows through
            // behind the bar, unlike the plain background on other tabs.
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: _isLoggedIn
                ? [
                    _buildTopSection(),
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
                    const SizedBox(height: 12),
                    _buildBookRequestButton(context),
                  ]
                : [
                    _buildLoggedOutSection(),
                    const SizedBox(height: 24),
                    _buildSettingsEntry(context),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedOutSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.16), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey2, size: 36)),
          ),
          const SizedBox(height: 18),
          Text(ProfileStrings.loginHeading, style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            ProfileStrings.loginBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.only(top: 24, bottom: 32),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              onPressed: _startLogin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedSmartPhone01, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(ProfileStrings.login, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _openEditProfile,
          child: Stack(
            children: [
              ProfileAvatar(index: _avatarIndex, size: 88, imageBase64: _avatarImage),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 2),
                  ),
                  child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Colors.white, size: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openEditProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_name, style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.grey3, size: 15),
            ],
          ),
        ),
        Text(_maskedPhone, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
      ],
    );
  }

  Widget _buildSubscriptionEntry(BuildContext context) {
    return _ProfileEntryCard(
      leading: _iconCircle(HugeIcons.strokeRoundedDiamond),
      title: ProfileStrings.subscription,
      subtitle: _hasSubscription ? ProfileStrings.daysLeft : ProfileStrings.subscribeNow,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return _ProfileEntryCard(
      leading: const SizedBox(width: 40, height: 40, child: StreakFlame(size: 32)),
      title: ProfileStrings.streakDays(StreakService.instance.currentStreak),
      subtitle: ProfileStrings.bestStreak(StreakService.instance.bestStreak),
      extra: StreakWeekRow(weekRead: StreakService.instance.weekRead, circleSize: 34),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakScreen())),
    );
  }

  Widget _buildFinanceEntry(BuildContext context) {
    return _ProfileEntryCard(
      leading: _iconCircle(HugeIcons.strokeRoundedWallet01),
      title: ProfileStrings.finance,
      subtitle: ProfileStrings.balanceManat(StreakService.instance.balanceManat),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
    );
  }

  Widget _buildSettingsEntry(BuildContext context) {
    return _ProfileEntryCard(
      leading: _iconCircle(HugeIcons.strokeRoundedSettings01),
      title: ProfileStrings.settingsEntryTitle,
      onTap: _openSettings,
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return _ProfileEntryCard(
      leading: _iconCircle(HugeIcons.strokeRoundedNote01),
      title: ProfileStrings.viewAllNotes,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
    );
  }

  Widget _buildBookRequestButton(BuildContext context) {
    return _ProfileEntryCard(
      leading: _iconCircle(HugeIcons.strokeRoundedBookOpen01),
      title: ProfileStrings.sendBookRequest,
      highlighted: true,
      onTap: () => BookRequestSheet.show(context),
    );
  }
}
