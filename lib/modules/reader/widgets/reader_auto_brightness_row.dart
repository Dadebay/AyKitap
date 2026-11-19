import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/widgets/settings_tiles.dart' show AppSwitch;

/// The same device-brightness toggle in all three reader settings sheets.
class ReaderAutoBrightnessRow extends StatelessWidget {
  const ReaderAutoBrightnessRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                HugeIcon(
                    icon: HugeIcons.strokeRoundedSun01,
                    color: AppColors.primary,
                    size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ReaderStrings.autoBrightnessLabel,
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(ReaderStrings.autoBrightnessHint,
                          style:
                              TextStyle(color: AppColors.grey2, fontSize: 11)),
                    ],
                  ),
                ),
                AppSwitch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      );
}
