import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import 'reader_fit_tile.dart';
import 'reader_section_label.dart';

/// The "page scale" section of [CbzSettingsSheet] — only meaningful
/// page-at-a-time, since in continuous scroll every page already fills the
/// width by definition, so the caller only mounts this in [CbzViewMode.paged].
class CbzPageScaleSection extends StatelessWidget {
  final BoxFit fit;
  final ValueChanged<BoxFit> onFitChanged;

  const CbzPageScaleSection(
      {super.key, required this.fit, required this.onFitChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReaderSectionLabel(ReaderStrings.pdfFitLabel),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedFitToScreen,
                label: ReaderStrings.cbzFitContain,
                selected: fit == BoxFit.contain,
                onTap: () => onFitChanged(BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedMaximize01,
                label: ReaderStrings.cbzFitCover,
                selected: fit == BoxFit.cover,
                onTap: () => onFitChanged(BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}
