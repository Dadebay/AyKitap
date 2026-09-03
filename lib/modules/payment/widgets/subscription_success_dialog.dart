import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_motion.dart';

/// A focused entitlement-unlock confirmation.
///
/// Subscription success is a state change the user must understand, so the
/// lock opening once is the motion. RevenueCat can reuse this surface when
/// its entitlement becomes active; the dialog does not care which purchase
/// provider produced it.
class SubscriptionSuccessDialog extends StatefulWidget {
  const SubscriptionSuccessDialog({
    super.key,
    required this.planLabel,
    this.restored = false,
  });

  final String planLabel;

  /// Set for RevenueCat's "Restore purchases" outcome — swaps the headline
  /// for one that says purchases came back rather than implying a purchase
  /// just happened.
  final bool restored;

  static Future<void> show(
    BuildContext context,
    String planLabel, {
    bool restored = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) =>
          SubscriptionSuccessDialog(planLabel: planLabel, restored: restored),
    );
  }

  @override
  State<SubscriptionSuccessDialog> createState() =>
      _SubscriptionSuccessDialogState();
}

class _SubscriptionSuccessDialogState extends State<SubscriptionSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value != 0 || _controller.isAnimating) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.52, curve: AppMotion.easeOut),
    );
    final unlock = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 1, curve: AppMotion.easeOut),
    );

    // Restoring isn't a new purchase to celebrate — same reasoning as the
    // headline swap below — and reduced motion skips it like every other
    // animation in this dialog.
    final showConfetti = !widget.restored && !AppMotion.reduceMotion(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/animations/Confetti.json',
                  repeat: false,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          FadeTransition(
            opacity: entrance,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(entrance),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: unlock,
                      builder: (context, _) {
                        final opened = unlock.value >= 0.48;
                        return Transform.scale(
                          scale: 0.9 + (0.1 * unlock.value),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: AppGradients.journeyPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              opened
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 34,
                              semanticLabel:
                                  PaymentStrings.subscriptionSuccessTitle,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.restored
                          ? PaymentStrings.subscriptionRestoredTitle
                          : PaymentStrings.subscriptionSuccessTitle,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      PaymentStrings.subscriptionActivated(widget.planLabel),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.grey1,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          PaymentStrings.subscriptionSuccessCta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
