import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/account_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/revenue_cat_service.dart';
import 'name_entry_screen.dart';
import 'widgets/welcome_bonus_dialog.dart';

/// Every side effect a successful backend login needs, regardless of which
/// front door produced [result] — phone/OTP ([OtpVerifyScreen]) or Firebase
/// email/Google/Apple ([InternationalLoginScreen]). Extracted so those two
/// screens can't drift into two slightly-different copies of this chain
/// (see the Faz H spec's explicit warning against exactly that).
///
/// [phone] is only set from the OTP path — [AuthSession.saveToken] records
/// it for display (e.g. "logged in as +993...") and it stays null for a
/// Firebase login, which has no phone number.
///
/// Same "brand-new account" signal both paths share: the backend returns
/// `user.username == null` only for a signup, never a login, which is what
/// gates the mandatory [NameEntryScreen] step and the one-time welcome bonus.
Future<void> completeBackendLogin(
  BuildContext context,
  VerifyLoginResult result, {
  String? phone,
  String loginMethod = 'phone',
}) async {
  await AuthSession.saveToken(result.accessToken, phone: phone);
  await AuthSession.saveUserId(result.user.id);
  unawaited(AnalyticsService.instance.logLogin(loginMethod: loginMethod));
  // Boot-time token fetch in FirebaseMessagingService.init() ran before this
  // login existed, so its own sync was a no-op — push it now instead of
  // waiting for the next onTokenRefresh event.
  unawaited(FirebaseMessagingService.instance.syncCurrentTokenIfLoggedIn());
  // Binds this device to the account on the *other* push provider. Safe to
  // fire before OneSignal has finished initialising — the intent is queued
  // and applied once it has (see OneSignalService's `_pendingIdentity`).
  unawaited(OneSignalService.instance.login(result.user.id));
  // Binds this device's store purchases to the account id too, so a
  // subscription bought under one account never appears active for the next
  // person who logs in on this device.
  unawaited(RevenueCatService.instance.login(result.user.id));

  final username = result.user.username;
  final isNewAccount = username == null || username.isEmpty;
  if (isNewAccount) {
    // Mandatory: no back arrow, no skip — see NameEntryScreen's PopScope.
    if (!context.mounted) return;
    final name = await context.push<String>(const NameEntryScreen());
    if (name != null) await AuthSession.saveName(name);
  } else {
    await AuthSession.saveName(username);
  }
  if (!context.mounted) return;
  // Every login needs this — [ProfileScreen] and friends watch
  // [AccountService] for the balance/user record, which otherwise stays
  // whatever it was before this login (null on a cold start) until
  // something else happens to trigger a refresh.
  await context.read<AccountService>().refresh();
  if (!context.mounted) return;
  // Only a genuine signup gets the welcome-bonus celebration — an existing
  // user logging back in already knows about (and has likely already spent)
  // whichever balance the backend credited them at signup, so re-showing
  // this every login would just be noise.
  if (isNewAccount) {
    final balance = context.read<AccountService>().balanceManat;
    if (balance != null && balance > 0) {
      await WelcomeBonusDialog.show(context, amount: '$balance');
    }
  }
}
