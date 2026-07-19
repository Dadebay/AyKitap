import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';

/// How the PDF page is coloured on screen. Unlike reflowable EPUB text, a PDF
/// page is a fixed picture, so each mode reaches the page differently:
///
/// * [light] — the page as authored, on a white gutter.
/// * [sepia] — an eye-care warm tint laid *over* the page (a translucent amber
///   wash), plus a warm gutter. Works on every platform because it's a Flutter
///   overlay, not a change to how the page is rendered.
/// * [night] — the page colour-inverted to light-on-dark (the "göz goraýyş"
///   dark reading other apps show), on a dark gutter. The inversion is done by
///   PDFium's night mode, which is **Android-only**; on iOS this falls back to
///   the plain page on a dark gutter.
enum PdfColorMode { light, sepia, night }

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
  final FitPolicy fitPolicy;
  final ValueChanged<PdfColorMode> onColorModeChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<FitPolicy> onFitChanged;

  const PdfSettingsSheet({
    super.key,
    required this.colorMode,
    required this.brightness,
    required this.fitPolicy,
    required this.onColorModeChanged,
    required this.onBrightnessChanged,
    required this.onFitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey3, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                ReaderStrings.settingsTitle,
                style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, color: AppColors.grey2, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Reading colour mode ───────────────────────────────────────
          // Three page treatments (light / eye-care sepia / night), each a
          // card the same footprint as the fit tiles below so the sheet reads
          // as one aligned grid. The swatch shows what the page will look like.
          _SectionLabel(ReaderStrings.pdfColorModeLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ColorModeSwatch(
                  color: Colors.white,
                  label: ReaderStrings.themeWhite,
                  selected: colorMode == PdfColorMode.light,
                  onTap: () => onColorModeChanged(PdfColorMode.light),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ColorModeSwatch(
                  color: const Color(0xFFEADFC6),
                  label: ReaderStrings.themeSepia,
                  selected: colorMode == PdfColorMode.sepia,
                  onTap: () => onColorModeChanged(PdfColorMode.sepia),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ColorModeSwatch(
                  color: const Color(0xFF1C1C1E),
                  label: ReaderStrings.themeNight,
                  selected: colorMode == PdfColorMode.night,
                  onTap: () => onColorModeChanged(PdfColorMode.night),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Page scale ────────────────────────────────────────────────
          _SectionLabel(ReaderStrings.pdfFitLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FitTile(
                  icon: HugeIcons.strokeRoundedArrowLeftRight,
                  label: ReaderStrings.pdfFitWidth,
                  selected: fitPolicy == FitPolicy.WIDTH,
                  onTap: () => onFitChanged(FitPolicy.WIDTH),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FitTile(
                  icon: HugeIcons.strokeRoundedFitToScreen,
                  label: ReaderStrings.pdfFitPage,
                  selected: fitPolicy == FitPolicy.BOTH,
                  onTap: () => onFitChanged(FitPolicy.BOTH),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ── Brightness (TZ §12.4) ──────────────────────────────────────
          // A full-width slider row rather than the EPUB panel's vertical
          // "fill level" tile: that shape only reads as a set, side by side
          // with the size/spacing tiles it has there — alone, it was a
          // narrow box floating in the middle of otherwise full-width rows.
          _SectionLabel(ReaderStrings.brightnessLabel),
          const SizedBox(height: 10),
          _BrightnessRow(value: brightness, onChanged: onBrightnessChanged),
        ],
      ),
    );
  }
}

/// Full-width brightness slider: dim icon, track, bright icon — the familiar
/// shape for a single-value control, matching the width of every other row in
/// this sheet instead of standing out as a differently-shaped tile.
class _BrightnessRow extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _BrightnessRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedSun01, color: AppColors.grey3, size: 15),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.13),
              ),
              child: Slider(value: value.clamp(0.1, 1.0), min: 0.1, max: 1.0, onChanged: onChanged),
            ),
          ),
          HugeIcon(icon: HugeIcons.strokeRoundedSun01, color: AppColors.grey1, size: 21),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: AppColors.grey2, fontSize: 12.5, fontWeight: FontWeight.w600));
  }
}

/// One reading colour mode, previewed by the colour the page takes on. Same
/// card footprint as [_FitTile] (height, radius, border) so the rows line up as
/// one grid; the colour fills the card instead of an icon, with a tick over it
/// once picked and the label sitting on top in a contrasting colour.
class _ColorModeSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorModeSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = color.computeLuminance() < 0.4 ? Colors.white : Colors.black87;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedTick02,
                color: selected ? onColor : Colors.transparent,
                size: 18,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: onColor, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page-scale option, styled like the EPUB font tiles: filled accent when
/// selected, outlined when idle.
class _FitTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FitTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, color: selected ? Colors.white : AppColors.grey2, size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.grey2,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
