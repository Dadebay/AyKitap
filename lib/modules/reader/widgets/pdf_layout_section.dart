import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'pdf_settings_sheet.dart';
import 'reader_fit_tile.dart';
import 'reader_section_label.dart';
import '../../../core/localization/strings/reader_pdf_strings.dart';

/// The "view mode" and "page scale" sections of [PdfSettingsSheet], grouped
/// together since they're the two halves of one choice — see
/// `PdfReaderScreen._setViewMode` for why picking a view mode also moves the
/// fit to whichever one actually works with it.
class PdfLayoutSection extends StatelessWidget {
  final PdfViewMode viewMode;
  final PdfFitMode fitPolicy;
  final ValueChanged<PdfViewMode> onViewModeChanged;
  final ValueChanged<PdfFitMode> onFitChanged;

  const PdfLayoutSection({
    super.key,
    required this.viewMode,
    required this.fitPolicy,
    required this.onViewModeChanged,
    required this.onFitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── View mode ─────────────────────────────────────────────────
        // Sits above the scale tiles because it's the coarser choice of
        // the two, and picking it also moves the scale to the one that
        // actually works with it.
        ReaderSectionLabel(ReaderPdfStrings.pdfViewModeLabel),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedScrollHorizontal,
                label: ReaderPdfStrings.pdfViewModePaged,
                selected: viewMode == PdfViewMode.paged,
                onTap: () => onViewModeChanged(PdfViewMode.paged),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedScrollVertical,
                label: ReaderPdfStrings.pdfViewModeScroll,
                selected: viewMode == PdfViewMode.scroll,
                onTap: () => onViewModeChanged(PdfViewMode.scroll),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── Page scale ────────────────────────────────────────────────
        ReaderSectionLabel(ReaderPdfStrings.pdfFitLabel),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedArrowLeftRight,
                label: ReaderPdfStrings.pdfFitWidth,
                selected: fitPolicy == PdfFitMode.width,
                onTap: () => onFitChanged(PdfFitMode.width),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReaderFitTile(
                icon: HugeIcons.strokeRoundedFitToScreen,
                label: ReaderPdfStrings.pdfFitPage,
                selected: fitPolicy == PdfFitMode.page,
                onTap: () => onFitChanged(PdfFitMode.page),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
