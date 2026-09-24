import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/profile/widgets/balance_increase_dialog.dart';
import '../navigation/root_navigator.dart';
import 'account_service.dart';
import 'auth_session.dart';

/// Tells a reader that money arrived while they weren't looking — in practice
/// a gift another reader sent them with "send to friend".
///
/// The backend sends no "you were paid" signal of any kind: no push, and the
/// transfer's incoming row is written against the *sender's* account, so the
/// recipient's `GET /users/balance-logs` doesn't carry it either. The one
/// thing the recipient's device can see is the balance itself, so that is
/// what this watches: `/users/me` is re-read when the app comes to the front,
/// and a total higher than the one last persisted is announced as a credit.
///
/// Consequences of working from the balance rather than from an event, all of
/// them deliberate:
///
/// * It reports *what changed*, not who sent it or why — the delta is the
///   only honest thing it knows.
/// * It cannot fire while the app is closed. A real push needs the backend.
/// * Several credits arriving between two checks are announced as one sum,
///   which is what a reader would expect from "your balance went up".
///
/// The baseline is per account ([AuthSession.getUserId]) so a second reader
/// signing in on the same device never inherits the first one's figure, and
/// an account seen for the first time is only recorded, never announced —
/// there is no "before" to have gone up from.
class BalanceAlertService with WidgetsBindingObserver {
  BalanceAlertService._();

  static final instance = BalanceAlertService._();

  /// Test seam — a service with no observer registered and no global state
  /// shared with [instance]. Call [check] directly instead of [init].
  @visibleForTesting
  factory BalanceAlertService.forTest() => BalanceAlertService._();

  static const _keyPrefix = 'balance_alert_last_seen_';

  bool _started = false;
  bool _checking = false;
  bool _ignoreNextIncrease = false;

  /// Registers the lifecycle observer and takes the opening reading. Safe to
  /// call more than once — the second call is a no-op — and never throws:
  /// this is a courtesy notice, and nothing about app start may depend on it.
  Future<void> init() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(check());
  }

  /// Suppresses exactly one announcement, for a credit this app itself just
  /// made happen.
  ///
  /// Every in-app top-up funnels through `startBalanceTopUp`, and two of its
  /// three routes leave the app on the way (Play's billing activity, the
  /// bank's payment page) — so the return trip is a `resumed` this service
  /// would otherwise read as money arriving out of nowhere, on top of the
  /// success UI the reader is already looking at. Cleared by the next
  /// [check] whether or not the balance actually moved, so a cancelled
  /// purchase can't leave it armed against a real gift later.
  void ignoreNextIncrease() => _ignoreNextIncrease = true;

  Future<void> check() async {
    // Overlapping checks would race on the stored baseline and could
    // announce the same credit twice — a cold start's own [init] call and a
    // `resumed` landing together is the ordinary way that happens.
    if (_checking) return;
    _checking = true;
    try {
      await _check();
    } catch (_) {
      // Best-effort by design: a failed read just means the announcement
      // waits for the next time the app comes to the front.
    } finally {
      _checking = false;
    }
  }

  Future<void> _check() async {
    final token = await AuthSession.getToken();
    if (token == null) return;
    final userId = await AuthSession.getUserId();
    if (userId == null) return;

    await AccountService.instance.refresh();
    final balance = AccountService.instance.balanceManat;
    // Null means the read failed and the last known record was kept — not
    // that the account is empty. Writing that as a baseline would announce a
    // phantom credit on the next successful read.
    if (balance == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$userId';
    final previous = prefs.getInt(key);
    await prefs.setInt(key, balance);

    final suppressed = _ignoreNextIncrease;
    _ignoreNextIncrease = false;
    if (previous == null || suppressed) return;
    if (balance <= previous) return;

    await _announce(balance - previous);
  }

  /// Uses the root overlay's context, the same one [StreakServiceReporting]
  /// shows its reward dialog from — this runs from a lifecycle callback and
  /// has no context of its own. A null overlay means the app has no frame up
  /// yet; the baseline is already stored either way, so skipping here costs
  /// the announcement, not the money.
  Future<void> _announce(int amount) async {
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    await BalanceIncreaseDialog.show(context, amount: amount);
  }
}
