import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import 'reader_fit_tile.dart';

/// The CBZ reader's settings panel — [PdfSettingsSheet]'s sibling, same
/// layout and same three sections (gutter colour, page scale, brightness), but
/// scaling the *image* pages with Flutter's own [BoxFit] instead of
/// flutter_pdfview's [FitPolicy], since a comic page here is drawn by
/// `Image.file` rather than a native PDF view.
class CbzSettingsSheet extends StatelessWidget {
  final bool darkGutter;
  final double brightness;
  final double eyeCare;
  final BoxFit fit;
  final ValueChanged<bool> onGutterChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onEyeCareChanged;
  final ValueChanged<BoxFit> onFitChanged;

  const CbzSettingsSheet({
    super.key,
    required this.darkGutter,
    required this.brightness,
    required this.eyeCare,
    required this.fit,
    required this.onGutterChanged,
    required this.onBrightnessChanged,
    required this.onEyeCareChanged,
    required this.onFitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Text(
                ReaderStrings.settingsTitle,
                style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: AppColors.card, shape: BoxShape.circle),
                  child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      color: AppColors.grey2,
                      size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Gutter colour ─────────────────────────────────────────────
          _SectionLabel(ReaderStrings.backgroundColorLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GutterSwatch(
                  color: Colors.white,
                  label: ReaderStrings.themeWhite,
                  selected: !darkGutter,
                  onTap: () => onGutterChanged(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GutterSwatch(
                  color: const Color(0xFF1C1C1E),
                  label: ReaderStrings.themeDark,
                  selected: darkGutter,
                  onTap: () => onGutterChanged(true),
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

          // ── Brightness (TZ §12.4) ──────────────────────────────────────
          _SectionLabel(ReaderStrings.brightnessLabel),
          const SizedBox(height: 10),
          _SliderRow(
            leadingIcon: HugeIcons.strokeRoundedSun01,
            trailingIcon: HugeIcons.strokeRoundedSun01,
            value: brightness,
            min: 0.1,
            onChanged: onBrightnessChanged,
          ),

          const SizedBox(height: 22),

          // ── Eye care (blue-light filter) ───────────────────────────────
          // A warm amber wash over the page, shared with the EPUB/PDF readers.
          _SectionLabel(ReaderStrings.eyeCareLabel),
          const SizedBox(height: 10),
          _SliderRow(
            leadingIcon: HugeIcons.strokeRoundedViewOff,
            trailingIcon: HugeIcons.strokeRoundedEye,
            value: eyeCare,
            min: 0.0,
            onChanged: onEyeCareChanged,
          ),
        ],
      ),
    );
  }
}

/// Full-width slider row: small leading icon, track, larger trailing icon.
/// Reused for both brightness and the eye-care filter; [min] lets the eye-care
/// slider reach fully off (0) while brightness bottoms out at 0.1.
class _SliderRow extends StatelessWidget {
  final List<List<dynamic>> leadingIcon;
  final List<List<dynamic>> trailingIcon;
  final double value;
  final double min;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.leadingIcon,
    required this.trailingIcon,
    required this.value,
    required this.min,
    required this.onChanged,
  });

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
          HugeIcon(icon: leadingIcon, color: AppColors.grey3, size: 15),
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
              child: Slider(
                  value: value.clamp(min, 1.0),
                  min: min,
                  max: 1.0,
                  onChanged: onChanged),
            ),
          ),
          HugeIcon(icon: trailingIcon, color: AppColors.grey1, size: 21),
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
    return Text(text,
        style: TextStyle(
            color: AppColors.grey2,
            fontSize: 12.5,
            fontWeight: FontWeight.w600));
  }
}

class _GutterSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GutterSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onColor =
        color.computeLuminance() < 0.4 ? Colors.white : Colors.black87;
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
                style: TextStyle(
                    color: onColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
