import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../provider/reader_provider.dart';
import 'reader_level_tile.dart';

/// Size / line spacing / brightness / eye care — the row of four vertical
/// "fill level" tiles in [ReaderSettingsSheet]. Expanded (not fixed-width) so
/// all four fit side by side on narrow phones without overflowing.
class ReaderAppearanceLevelsRow extends StatelessWidget {
  final ReaderProvider provider;
  const ReaderAppearanceLevelsRow({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ReaderLevelTile(
            iconBuilder: (c) => Text(
              'Aa',
              style: TextStyle(
                  color: c, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            label: ReaderStrings.fontSizeLabel,
            valueText: '${provider.fontSize.round()}',
            value: provider.fontSize,
            min: ReaderProvider.minFontSize,
            max: ReaderProvider.maxFontSize,
            onChanged: provider.setFontSize,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ReaderLevelTile(
            iconBuilder: (c) => HugeIcon(
                icon: HugeIcons.strokeRoundedLeftToRightListDash,
                color: c,
                size: 20),
            label: ReaderStrings.lineSpacingLabel,
            valueText: provider.lineSpacing.toStringAsFixed(1),
            value: provider.lineSpacing,
            min: 1.0,
            max: 2.5,
            onChanged: provider.setLineSpacing,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ReaderLevelTile(
            iconBuilder: (c) => HugeIcon(
                icon: HugeIcons.strokeRoundedSun01, color: c, size: 20),
            label: ReaderStrings.brightnessLabel,
            valueText: '${(provider.brightness * 100).round()}%',
            value: provider.brightness,
            min: 0.1,
            max: 1.0,
            onChanged: provider.setBrightness,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ReaderLevelTile(
            iconBuilder: (c) =>
                HugeIcon(icon: HugeIcons.strokeRoundedEye, color: c, size: 20),
            label: ReaderStrings.eyeCareLabel,
            valueText: provider.eyeCare <= 0.0
                ? '0%'
                : '${(provider.eyeCare * 100).round()}%',
            value: provider.eyeCare,
            min: 0.0,
            max: 1.0,
            onChanged: provider.setEyeCare,
          ),
        ),
      ],
    );
  }
}
