import 'package:flutter/material.dart';
import '../../../core/localization/strings/reader_strings.dart';
import 'pdf_color_mode_swatch.dart';
import 'pdf_settings_sheet.dart';
import 'reader_section_label.dart';

/// The "reading colour mode" section of [PdfSettingsSheet]: three page
/// treatments (light / eye-care sepia / night), each a card the same
/// footprint as the fit tiles below so the sheet reads as one aligned grid.
class PdfColorModeSection extends StatelessWidget {
  final PdfColorMode colorMode;
  final ValueChanged<PdfColorMode> onChanged;

  const PdfColorModeSection(
      {super.key, required this.colorMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReaderSectionLabel(ReaderStrings.pdfColorModeLabel),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PdfColorModeSwatch(
                color: Colors.white,
                label: ReaderStrings.themeWhite,
                selected: colorMode == PdfColorMode.light,
                onTap: () => onChanged(PdfColorMode.light),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PdfColorModeSwatch(
                color: const Color(0xFFEADFC6),
                label: ReaderStrings.themeSepia,
                selected: colorMode == PdfColorMode.sepia,
                onTap: () => onChanged(PdfColorMode.sepia),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PdfColorModeSwatch(
                color: const Color(0xFF1C1C1E),
                label: ReaderStrings.themeNight,
                selected: colorMode == PdfColorMode.night,
                onTap: () => onChanged(PdfColorMode.night),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
