import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_colors.dart';

/// [SendGiftSheet]'s failed-send message, shown just above the Send button.
///
/// This exists because the app's usual error surface can't be seen from that
/// sheet: [AppSnackBar] floats at the bottom of the screen with a nav-bar
/// sized margin, and the sheet — plus the keyboard it opens with — covers
/// exactly that strip. A reader who tried to gift more than their balance
/// got a rejection they never saw, and a Send button that looked like it
/// simply did nothing.
///
/// Red rather than the app's usual accent, and paired with an alert glyph,
/// so it reads as a refusal at a glance instead of as another hint line.
class GiftErrorNote extends StatelessWidget {
  final String message;

  const GiftErrorNote(this.message, {super.key});

  /// The same red [BalanceLogTile] gives a debit, so "money leaving didn't
  /// work" and "money left" are the same colour throughout this flow.
  static const _errorColor = Color(0xFFE65C5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _errorColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _errorColor.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: _errorColor,
              size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
