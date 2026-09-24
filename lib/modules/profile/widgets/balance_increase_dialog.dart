import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../balance_screen.dart';

/// Announces a balance the app found higher than it last saw it — in practice
/// a gift another reader sent while this app was closed or in the background.
/// [BalanceAlertService] is the only caller.
///
/// Same confetti-over-a-card shape as [WelcomeBonusDialog], because it says
/// the same kind of thing (money arrived, here is what to spend it on) and a
/// reader who has seen the signup one should recognise this immediately. It
/// differs where it matters: this one has somewhere to go, so its primary
/// action opens [BalanceScreen] rather than just closing.
class BalanceIncreaseDialog extends StatelessWidget {
  final int amount;
  const BalanceIncreaseDialog({super.key, required this.amount});

  /// Resolves with the dialog; if the reader chose "view balance", the
  /// balance screen is pushed first and this only returns once they come
  /// back from it — so a second queued announcement can't land on top of it.
  static Future<void> show(BuildContext context, {required int amount}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => BalanceIncreaseDialog(amount: amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset('assets/animations/Confetti.json',
                  repeat: false, fit: BoxFit.cover),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle),
                  child: Center(
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedWallet01,
                          color: AppColors.primary,
                          size: 34)),
                ),
                const SizedBox(height: 18),
                Text(ProfileStrings.balanceIncreasedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                  ProfileStrings.balanceIncreasedBody(amount),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.grey1, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openBalance(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(ProfileStrings.balanceIncreasedView,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(ProfileStrings.balanceIncreasedDismiss,
                      style: TextStyle(
                          color: AppColors.grey1,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Closes the dialog first, then pushes — pushing from under a dialog
  /// leaves the barrier sitting over the screen the reader just asked for.
  ///
  /// The route goes onto the [NavigatorState] directly rather than through
  /// `context.push`: that extension resolves `Navigator.of(context)`, and the
  /// only context still alive after the pop is the navigator's own, from
  /// which `Navigator.of` would look *past* it to an ancestor.
  void _openBalance(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
        MaterialPageRoute<void>(builder: (_) => const BalanceScreen()));
  }
}
