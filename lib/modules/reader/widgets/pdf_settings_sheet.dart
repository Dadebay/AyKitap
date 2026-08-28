import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'pdf_appearance_sliders.dart';
import 'pdf_color_mode_section.dart';
import 'pdf_layout_section.dart';
import 'pdf_text_view_row.dart';
import 'reader_sheet_header.dart';

/// How the PDF page is coloured on screen. Unlike reflowable EPUB text, a PDF
/// page is a fixed picture, so each mode reaches the page differently:
///
/// * [light] — the page as authored, on a white gutter.
/// * [sepia] — an eye-care warm tint laid *over* the page (a translucent amber
///   wash), plus a warm gutter. Works on every platform because it's a Flutter
///   overlay, not a change to how the page is rendered.
/// * [night] — the page colour-inverted to light-on-dark (the "göz goraýyş"
///   dark reading other apps show), on a dark gutter. The inversion is a
///   Flutter [ColorFiltered] layer over the rendered page, so unlike the
///   PDFium night mode this used to rely on it behaves the same on Android
///   and iOS instead of silently doing nothing on one of them.
enum PdfColorMode { light, sepia, night }

/// How pages are laid out and moved through.
///
/// * [paged] — one page per sideways swipe, like turning a book page. Pairs
///   with [PdfFitMode.page]: the whole page has to be on screen, since there's
///   nothing to scroll to if part of it falls below the fold.
/// * [scroll] — every page stacked in one continuous top-to-bottom scroll.
///   This is what makes a very tall page readable: paired with
///   [PdfFitMode.width] the page fills the screen's width and you scroll down
///   through it, instead of the whole strip being shrunk to fit the screen's
///   *height* and rendering as a narrow, unreadable column (which is exactly
///   what a webtoon/manhwa PDF does in [paged] + [PdfFitMode.page]).
enum PdfViewMode { paged, scroll }

/// How much of a page is scaled to fit the screen.
///
/// Replaces flutter_pdfview's `FitPolicy` — [width] was `FitPolicy.WIDTH`,
/// [page] was `FitPolicy.BOTH` — now that pages are drawn by pdfrx. See
/// [PdfViewMode] for why each mode pairs with one of these.
enum PdfFitMode { width, page }

/// The PDF reader's settings panel — the counterpart of [ReaderSettingsSheet],
/// built from the same pieces (grab handle, heading with a dismiss circle,
/// section labels) so the two readers feel like one app. Every section is a
/// full-width row of same-height cards (or, for brightness, a full-width
/// slider), so the sheet reads as one aligned grid rather than pieces of
/// different sizes scattered down the page.
///
/// It offers only what a fixed-layout page can honour: the gutter colour behind
/// the page, screen brightness (TZ §12.4), and how the page is scaled. The EPUB
/// panel's font, size and line-spacing controls have nothing to act on here —
/// a PDF page is a picture, not text that can reflow — so they're absent rather
/// than present and dead.
class PdfSettingsSheet extends StatelessWidget {
  final PdfColorMode colorMode;
  final double brightness;
  final double eyeCare;
  final PdfFitMode fitPolicy;
  final PdfViewMode viewMode;

  /// How far the page's blank print margins are trimmed, 0 (leave them) to 1
  /// (the widest crop [PdfMarginCropBox] allows).
  final double marginCrop;
  final ValueChanged<PdfColorMode> onColorModeChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onEyeCareChanged;
  final ValueChanged<double> onMarginCropChanged;
  final ValueChanged<PdfFitMode> onFitChanged;
  final ValueChanged<PdfViewMode> onViewModeChanged;

  /// Set only when this PDF was previously reflowed into text (a cached
  /// conversion exists) and the reader chose to fall back to these fixed
  /// pages — offers a way back to the reflowable text view.
  final VoidCallback? onSwitchToTextView;

  const PdfSettingsSheet({
    super.key,
    required this.colorMode,
    required this.brightness,
    required this.eyeCare,
    required this.fitPolicy,
    required this.viewMode,
    required this.marginCrop,
    required this.onColorModeChanged,
    required this.onBrightnessChanged,
    required this.onEyeCareChanged,
    required this.onMarginCropChanged,
    required this.onFitChanged,
    required this.onViewModeChanged,
    this.onSwitchToTextView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Rotating the reader (see reader_orientation.dart) leaves this sheet
      // roughly half its portrait height, which isn't enough for every section
      // below — so cap it and let the body scroll, exactly as
      // [ReaderSettingsSheet] does. Without the cap the Column simply
      // overflowed the viewport in landscape.
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
                  // ── Reading colour mode ───────────────────────────────────────
                  PdfColorModeSection(
                      colorMode: colorMode, onChanged: onColorModeChanged),

                  const SizedBox(height: 22),

                  // ── View mode + page scale ─────────────────────────────────────
                  PdfLayoutSection(
                    viewMode: viewMode,
                    fitPolicy: fitPolicy,
                    onViewModeChanged: onViewModeChanged,
                    onFitChanged: onFitChanged,
                  ),

                  const SizedBox(height: 22),

                  // ── Page margins, brightness, eye care ─────────────────────────
                  PdfAppearanceSliders(
                    marginCrop: marginCrop,
                    brightness: brightness,
                    eyeCare: eyeCare,
                    onMarginCropChanged: onMarginCropChanged,
                    onBrightnessChanged: onBrightnessChanged,
                    onEyeCareChanged: onEyeCareChanged,
                  ),

                  // ── Back to the reflowable text view ───────────────────────────
                  if (onSwitchToTextView != null) ...[
                    const SizedBox(height: 22),
                    PdfTextViewRow(
                      onTap: () {
                        Navigator.pop(context);
                        onSwitchToTextView!();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
