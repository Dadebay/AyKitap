import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_navigator.dart';
import '../../core/services/revenue_cat_api_service.dart';
import 'store_subscription_screen.dart';
import 'subscription_screen.dart';

/// Guards every call below against a second tap landing while the first
/// one's [RevenueCatApiService.getConfig] round-trip is still in flight —
/// without it, a tap that produces no visible change for a second or two
/// reads as "didn't register" and gets repeated, stacking that many pushes
/// of the resolved screen once the awaits all resolve.
bool _isOpening = false;

/// Routes to whichever subscription screen can actually take the signed-in
/// user's money — [RevenueCatApiService.getConfig] resolves a Turkmenistan
/// account to the TMT/[SubscriptionScreen] (bank card, promo code, balance)
/// and everyone else to the store-billed [StoreSubscriptionScreen] (App
/// Store/Play Store via RevenueCat). Every "subscribe" entry point in the
/// app should go through this instead of pushing [SubscriptionScreen]
/// directly — that screen has no bank cards to offer a foreign user, so
/// they'd land on a plan list with no way to complete a purchase.
///
/// Fails closed to [SubscriptionScreen] on a config error (no network,
/// backend down) — same reasoning as [startBalanceTopUp]'s store gate:
/// showing today's default screen beats showing nothing.
Future<void> openSubscriptionScreen(BuildContext context) async {
  if (_isOpening) return;
  _isOpening = true;
  // Immediate feedback for the [getConfig] round-trip below — a cold
  // RevenueCat SDK (fetching remote config, offerings and store product
  // details, as seen in the debug logs) can take a couple of seconds, and
  // this screen would otherwise sit there looking untouched the whole time.
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    builder: (_) =>
        const Center(child: CircularProgressIndicator(color: Colors.white)),
  ));
  var useStore = false;
  try {
    final config = await RevenueCatApiService.getConfig();
    useStore = config.isStoreIap;
  } catch (_) {
    // Falls through to the wallet screen.
  } finally {
    _isOpening = false;
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  await context.push(
    useStore ? const StoreSubscriptionScreen() : const SubscriptionScreen(),
  );
}
