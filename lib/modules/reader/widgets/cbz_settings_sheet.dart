import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'cbz_gutter_swatch.dart';
import 'cbz_page_scale_section.dart';
import 'reader_fit_tile.dart';
import 'reader_section_label.dart';
import 'reader_sheet_header.dart';
import 'reader_slider_row.dart';
import '../../../core/localization/strings/reader_pdf_strings.dart';

/// How a CBZ's page images are laid out and moved through — the image-book
/// counterpart of [PdfViewMode], and the same trade-off.
///
/// * [scroll] — every page stacked in one continuous top-to-bottom scroll,
///   each drawn at the full screen width. This is the default: a comic page is
///   typically much taller than the screen, so fitting it whole shrinks the
///   panels and lettering to an unreadable size. Filling the width and letting
///   the reader scroll down the page is how comics are read.
/// * [paged] — one page per sideways swipe, scaled to fit the screen whole.
///   Opt-in, for the reader who wants a page at a time.
enum CbzViewMode { scroll, paged }

/// The CBZ reader's settings panel — [PdfSettingsSheet]'s sibling, same
/// layout and same three sections (gutter colour, page scale, brightness), but
/// scaling the *image* pages with Flutter's own [BoxFit] instead of
/// [PdfFitMode], since a comic page here is drawn by `Image.file` rather
/// than by a PDF engine.
class CbzSettingsSheet extends StatelessWidget {
  final bool darkGutter;
  final double brightness;
  final double eyeCare;
  final BoxFit fit;
  final CbzViewMode viewMode;
  final ValueChanged<bool> onGutterChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onEyeCareChanged;
  final ValueChanged<BoxFit> onFitChanged;
  final ValueChanged<CbzViewMode> onViewModeChanged;

  const CbzSettingsSheet({
    super.key,
    required this.darkGutter,
    required this.brightness,
    required this.eyeCare,
    required this.fit,
    required this.viewMode,
    required this.onGutterChanged,
    required this.onBrightnessChanged,
    required this.onEyeCareChanged,
    required this.onFitChanged,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // See [PdfSettingsSheet] — same cap-and-scroll treatment, so the sheet
      // still fits once the reader is rotated into landscape.
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReaderSheetHeader(
            title: ReaderStrings.settingsTitle,
            closeIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                color: AppColors.grey2,
                size: 18),
          ),

          // Grab handle and heading stay put; everything below them scrolls,
          // so a short (landscape) viewport still reaches every section.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gutter colour ─────────────────────────────────────────────
                  ReaderSectionLabel(ReaderStrings.backgroundColorLabel),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CbzGutterSwatch(
                          color: Colors.white,
                          label: ReaderStrings.themeWhite,
                          selected: !darkGutter,
                          onTap: () => onGutterChanged(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CbzGutterSwatch(
                          color: const Color(0xFF1C1C1E),
                          label: ReaderStrings.themeDark,
                          selected: darkGutter,
                          onTap: () => onGutterChanged(true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── View mode ─────────────────────────────────────────────────
                  // Above the scale tiles for the same reason as in
                  // [PdfSettingsSheet]: it's the coarser choice, and picking it
                  // also moves the scale to the one that works with it.
                  ReaderSectionLabel(ReaderPdfStrings.pdfViewModeLabel),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ReaderFitTile(
                          icon: HugeIcons.strokeRoundedScrollVertical,
                          label: ReaderPdfStrings.pdfViewModeScroll,
                          selected: viewMode == CbzViewMode.scroll,
                          onTap: () => onViewModeChanged(CbzViewMode.scroll),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ReaderFitTile(
                          icon: HugeIcons.strokeRoundedScrollHorizontal,
                          label: ReaderPdfStrings.pdfViewModePaged,
                          selected: viewMode == CbzViewMode.paged,
                          onTap: () => onViewModeChanged(CbzViewMode.paged),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Page scale ────────────────────────────────────────────────
                  // Only meaningful page-at-a-time: in continuous scroll every
                  // page already fills the width by definition.
                  if (viewMode == CbzViewMode.paged)
                    CbzPageScaleSection(fit: fit, onFitChanged: onFitChanged),

                  // ── Brightness (TZ §12.4) ──────────────────────────────────────
                  ReaderSectionLabel(ReaderStrings.brightnessLabel),
                  const SizedBox(height: 10),
                  ReaderSliderRow(
                    leadingIcon: HugeIcons.strokeRoundedSun01,
                    trailingIcon: HugeIcons.strokeRoundedSun01,
                    value: brightness,
                    min: 0.1,
                    onChanged: onBrightnessChanged,
                  ),

                  const SizedBox(height: 22),

                  // ── Eye care (blue-light filter) ───────────────────────────────
                  // A warm amber wash over the page, shared with the EPUB/PDF readers.
                  ReaderSectionLabel(ReaderStrings.eyeCareLabel),
                  const SizedBox(height: 10),
                  ReaderSliderRow(
                    leadingIcon: HugeIcons.strokeRoundedViewOff,
                    trailingIcon: HugeIcons.strokeRoundedEye,
                    value: eyeCare,
                    min: 0.0,
                    onChanged: onEyeCareChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
