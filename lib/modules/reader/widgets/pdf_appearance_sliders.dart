import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_pdf_strings.dart';
import '../../../core/localization/strings/reader_strings.dart';
import 'reader_section_label.dart';
import 'reader_slider_row.dart';

/// [PdfSettingsSheet]'s three full-width sliders — page margins, brightness
/// and the eye-care filter — as one block, since they're the same shape and
/// read as a set. Split out of the sheet to keep that file under the
/// 200-line limit.
///
/// Each is a slider rather than a switch because the right amount differs per
/// book and per reader, and each bottoms out at "leave it alone" (except
/// brightness, which stops at a dim-but-still-visible 0.1).
class PdfAppearanceSliders extends StatelessWidget {
  final double marginCrop;
  final double brightness;
  final double eyeCare;
  final ValueChanged<double> onMarginCropChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onEyeCareChanged;

  const PdfAppearanceSliders({
    super.key,
    required this.marginCrop,
    required this.brightness,
    required this.eyeCare,
    required this.onMarginCropChanged,
    required this.onBrightnessChanged,
    required this.onEyeCareChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page margins ─────────────────────────────────────────────────
        // A printed page carries a blank margin down each side; left alone it
        // reads on screen as two empty strips with the text squeezed between
        // them. Dragging this right trims them off so the text block reaches
        // both edges. Zero leaves the page untouched; useful when a comic is
        // genuinely edge-to-edge rather than a scan carrying paper borders.
        ReaderSectionLabel(ReaderPdfStrings.pdfMarginCropLabel),
        const SizedBox(height: 10),
        ReaderSliderRow(
          leadingIcon: HugeIcons.strokeRoundedGridView,
          trailingIcon: HugeIcons.strokeRoundedFullScreen,
          value: marginCrop,
          min: 0.0,
          onChanged: onMarginCropChanged,
        ),

        const SizedBox(height: 22),

        // ── Brightness (TZ §12.4) ────────────────────────────────────────
        // A full-width slider row rather than the EPUB panel's vertical
        // "fill level" tile: that shape only reads as a set, side by side
        // with the size/spacing tiles it has there — alone, it was a narrow
        // box floating in the middle of otherwise full-width rows.
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

        // ── Eye care (blue-light filter) ─────────────────────────────────
        // A warm amber wash over the page to cut blue light; strength runs
        // from off (0) to warmest. Shared with the EPUB reader.
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
    );
  }
}
