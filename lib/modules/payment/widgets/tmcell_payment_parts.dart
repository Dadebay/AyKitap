import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/payment_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The pieces [TmcellPaymentScreen] is built from — the same bordered-card
/// vocabulary the rest of the payment module uses ([PaymentMethodSheet],
/// [TopUpAmountSheet]), kept here so the screen itself reads as a layout.

class TmcellSectionLabel extends StatelessWidget {
  const TmcellSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800));
}

/// The reader's own number, shown because the transfer only works from it —
/// a reader signed in on a second phone needs to see which line will be
/// charged before they send anything.
class TmcellMyNumberCard extends StatelessWidget {
  const TmcellMyNumberCard({super.key, required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedSmartPhone01,
              color: AppColors.primary,
              size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(PaymentStrings.tmcellMyNumber,
                style: TextStyle(color: AppColors.grey2, fontSize: 13)),
          ),
          Text(phone,
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// The line the money is transferred to, as the admin panel serves it.
///
/// Shown next to the reader's own number because those two numbers are what
/// the SMS is about, and the receiving one is the part a reader cannot
/// verify anywhere else before sending money to it. While it is still being
/// fetched the row keeps its place with a spinner rather than appearing
/// later and pushing the amount list down under the reader's thumb; when
/// there is nothing to show, it says so and offers a retry in the same spot.
class TmcellReceiverCard extends StatelessWidget {
  const TmcellReceiverCard({
    super.key,
    required this.phone,
    required this.loading,
    required this.onRetry,
  });

  final String? phone;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final missing = !loading && phone == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.primary,
              size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              missing
                  ? PaymentStrings.tmcellNumberUnavailable
                  : PaymentStrings.tmcellReceiverNumber,
              style: TextStyle(color: AppColors.grey2, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          if (loading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.grey3),
            )
          else if (missing)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(PaymentStrings.tmcellRetry,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            )
          else
            Text(phone!,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class TmcellAmountRow extends StatelessWidget {
  const TmcellAmountRow({
    super.key,
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.grey3,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text('$amount TMT',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class TmcellNoticeCard extends StatelessWidget {
  const TmcellNoticeCard({
    super.key,
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final List<List<dynamic>> icon;
  final String text;

  /// Tints the card red instead of neutral — for the one line a reader must
  /// not skim past (the transfer only works from a TMCELL line). The same
  /// red [AppSnackBar] uses for an error, so "something to be careful about"
  /// looks the same everywhere in the app.
  final bool warning;

  static const _warningRed = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final tint = warning ? _warningRed : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: tint, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: AppColors.grey1, fontSize: 13, height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class TmcellAgreementRow extends StatelessWidget {
  const TmcellAgreementRow(
      {super.key, required this.agreed, required this.onChanged});

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!agreed),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: agreed,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
              side: BorderSide(color: AppColors.grey3),
            ),
            Expanded(
              child: Text(PaymentStrings.tmcellAgreement,
                  style: TextStyle(color: AppColors.grey1, fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class TmcellSendButton extends StatelessWidget {
  const TmcellSendButton(
      {super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: enabled ? AppColors.primary : AppColors.grey3,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        // Always tappable: a disabled button gives no reason, and the reason
        // here is one line the reader can act on. See the screen's _send.
        onPressed: onTap,
        child: Text(PaymentStrings.tmcellSend,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
