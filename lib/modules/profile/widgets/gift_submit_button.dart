import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [SendGiftSheet]'s gradient submit button — "Iber" with the amount, or a
/// spinner mid-request.
class GiftSubmitButton extends StatelessWidget {
  final bool canSubmit;
  final bool sending;
  final int? amount;
  final VoidCallback? onPressed;

  const GiftSubmitButton(
      {super.key,
      required this.canSubmit,
      required this.sending,
      required this.amount,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: canSubmit
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    const Color(0xFFE85A73),
                  ],
                )
              : null,
          color: canSubmit ? null : AppColors.primary.withValues(alpha: .35),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: canSubmit ? onPressed : null,
          child: sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedGift,
                        color: Colors.white,
                        size: 19),
                    const SizedBox(width: 9),
                    Text(
                      amount != null
                          ? GiftStrings.sendWithAmount(amount!)
                          : GiftStrings.send,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Colors.white,
                        size: 17),
                  ],
                ),
        ),
      ),
    );
  }
}
