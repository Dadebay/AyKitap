import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/localization/strings/gift_strings.dart';
import '../../core/localization/strings/payment_strings.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/localization/strings/profile_feedback_strings.dart';
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
import 'widgets/active_subscription_card.dart';
import 'widgets/profile_entry_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/send_gift_sheet.dart';

part 'profile_screen_session.dart';
part 'profile_screen_entries.dart';

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

  void _setState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _refreshSession();
    StreakService.instance.load();
    SubscriptionService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AccountService>().balanceManat;
    final subscription = context.watch<SubscriptionService>();
    return Scaffold(
      // journeyMist rather than the app-wide AppColors.bg (TZ S5) — its dark
      // build is deliberately near-identical to AppColors.bg's own dark value
      // (#14131B vs #13131A), so this is a real but practically invisible
      // dark-mode choice: the airier tone only actually shows up in light
      // mode, and dark mode's existing contrast carries over unchanged.
      backgroundColor: AppColors.journeyMist,
      appBar: AppBar(
        backgroundColor: AppColors.journeyMist,
        scrolledUnderElevation: 0.0,
        centerTitle: true,
        title: Text(ProfileStrings.profileTitle,
            style: TextStyle(
                color: AppColors.journeyInk,
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
}
