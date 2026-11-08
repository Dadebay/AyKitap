import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'gift_section_label.dart';

/// [SendGiftSheet]'s step 1 — preset amount chips plus the free-entry field.
class GiftAmountSection extends StatelessWidget {
  final List<int> presets;
  final int? selectedAmount;
  final ValueChanged<int> onPresetTap;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  const GiftAmountSection({
    super.key,
    required this.presets,
    required this.selectedAmount,
    required this.onPresetTap,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GiftSectionLabel(GiftStrings.amountLabel, step: '1'),
        const SizedBox(height: 10),
        Row(
          children: presets.map((preset) {
            final selected = selectedAmount == preset;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: preset == presets.last ? 0 : 8),
                child: Semantics(
                  button: true,
                  selected: selected,
                  child: InkWell(
                    onTap: () => onPresetTap(preset),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: .14)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: .15),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$preset',
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.grey1,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    focusNode.hasFocus ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedWallet01,
                color: focusNode.hasFocus ? AppColors.primary : AppColors.grey3,
                size: 20,
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.border,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    hintText: GiftStrings.amountHint,
                    hintStyle: TextStyle(
                        color: AppColors.grey3,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                'TMT',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
