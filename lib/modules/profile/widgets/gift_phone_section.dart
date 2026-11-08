import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import 'gift_section_label.dart';

enum GiftUserCheckStatus { idle, checking, found, notFound, error }

/// [SendGiftSheet]'s step 2 — recipient phone input plus the live
/// [GiftUserCheckStatus] row once the number is complete.
class GiftPhoneSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool showStatus;
  final GiftUserCheckStatus status;

  const GiftPhoneSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.showStatus,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GiftSectionLabel(GiftStrings.phoneLabel, step: '2'),
        const SizedBox(height: 10),
        AppTextField(
          controller: controller,
          focusNode: focusNode,
          hint: '__ __ __ __',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11)
          ],
          style:
              TextStyle(color: AppColors.white, fontSize: 16, letterSpacing: 1),
          onChanged: onChanged,
          prefix: Row(
            children: [
              Text('+993',
                  style: TextStyle(
                      color: AppColors.grey1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 1,
                  height: 22,
                  color: AppColors.border),
            ],
          ),
        ),
        if (showStatus) ...[
          const SizedBox(height: 8),
          _buildStatus(),
        ],
      ],
    );
  }

  Widget _buildStatus() {
    switch (status) {
      case GiftUserCheckStatus.idle:
        return const SizedBox.shrink();
      case GiftUserCheckStatus.checking:
        return _statusRow(
          child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.grey2)),
          label: GiftStrings.checkingUser,
          color: AppColors.grey2,
        );
      case GiftUserCheckStatus.found:
        return _statusRow(
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
          label: GiftStrings.userFound,
          color: const Color(0xFF3FB950),
        );
      case GiftUserCheckStatus.notFound:
        return _statusRow(
          icon: HugeIcons.strokeRoundedCancelCircle,
          label: GiftStrings.userNotFound,
          color: const Color(0xFFE5484D),
        );
      case GiftUserCheckStatus.error:
        return _statusRow(
          icon: HugeIcons.strokeRoundedAlert02,
          label: GiftStrings.userCheckFailed,
          color: const Color(0xFFE5484D),
        );
    }
  }

  Widget _statusRow(
      {Widget? child,
      List<List<dynamic>>? icon,
      required String label,
      required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          child ?? HugeIcon(icon: icon!, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
