import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/account_service.dart';
import '../../core/services/purchase_mode_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/onesignal_service.dart';
import '../../core/services/revenue_cat_service.dart';
import 'name_entry_screen.dart';
import 'suggested_display_name.dart';
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
/// gates the [NameEntryScreen] step and the one-time welcome bonus.
///
/// [suggestedName] is the name the sign-in provider already gave us — see
/// [suggestedDisplayName]. When there is one, the signup is completed with
/// it instead of stopping to ask: App Store guideline 4 forbids asking for a
/// name that Sign in with Apple has already supplied. The phone/OTP door
/// passes nothing (it has nothing to pass) and still asks, which is what
/// that guideline is not about.
Future<void> completeBackendLogin(
  BuildContext context,
  VerifyLoginResult result, {
  String? phone,
  String loginMethod = 'phone',
  String? suggestedName,
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
  if (isNewAccount && suggestedName != null && suggestedName.isNotEmpty) {
    await AuthSession.saveName(suggestedName);
    // Best effort, exactly as [NameEntryScreen] does it, so the backend has
    // a username on file and never treats this account as new again. A
    // failure here must not put the prompt back: the name is recoverable
    // from Profile, an App Store rejection is not.
    try {
      await AuthApiService.updateUsername(username: suggestedName);
    } on ApiException catch (_) {
      // Keep the local name and carry on.
    }
  } else if (isNewAccount) {
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
  // Ödeme yüzeyi de bu kullanıcıya göre yeniden çözülmeli.
  //
  // `/revenuecat/config` oturum istiyor; uygulama açılışındaki ilk istek
  // henüz giriş yapılmadığı için 401 alıyor ve [PurchaseModeService]
  // güvenli tarafta kalıp iOS'u "yalnızca App Store" kabul ediyor. Burada
  // yenilenmezse admin anahtarı kapalı olsa bile satın alma butonu gizli,
  // bakiye sayfası "abone ol" hâlinde kalıyordu — ta ki kullanıcı
  // uygulamayı arka plana atıp geri açana kadar (yaşam döngüsü
  // dinleyicisi orada yeniliyor).
  await context.read<PurchaseModeService>().refresh();
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
