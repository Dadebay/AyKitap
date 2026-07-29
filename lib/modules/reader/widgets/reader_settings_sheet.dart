import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import 'page_transition_section.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/reader_strings.dart';

/// TZ §12.4 — the reader's settings panel: theme, font, size, line spacing
/// and brightness, with the §12.2 page-transition block as a row that opens
/// its own sheet. Scrolls, since the whole stack is taller than a
/// comfortable sheet on small screens.
///
/// Colours come from [AppColors] so the panel follows the *app* theme
/// (light/dark), independent of the reader's page theme — the swatch buttons
/// below still show their own fixed page colours.
class ReaderSettingsSheet extends StatelessWidget {
  /// Shown only when this reader is actually a synthetic EPUB generated from
  /// a PDF — offers a way back to the original fixed page images for a book
  /// whose source PDF has a broken font/text encoding (see
  /// [ReaderScreen.originalPdfPath]). Tapping it pops this sheet with `true`,
  /// which the reader screen reads to perform the actual switch.
  final bool showOriginalPdfOption;

  const ReaderSettingsSheet({super.key, this.showOriginalPdfOption = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  decoration: BoxDecoration(
                    color: AppColors.grey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Panel heading, with a chevron that dismisses the sheet.
              Row(
                children: [
                  Text(
                    ReaderStrings.settingsTitle,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                      child: Icon(Icons.keyboard_arrow_down, color: AppColors.grey2, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Theme (iOS-style: colour only, check = selected) ─
                      _SectionLabel(ReaderStrings.backgroundColorLabel),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ReaderThemeMode.values.map((mode) {
                          return _ThemeButton(
                            mode: mode,
                            selected: provider.themeMode == mode,
                            onTap: () => provider.setTheme(mode),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // ── Font family — a row of four preview tiles ──────
                      _SectionLabel(ReaderStrings.fontLabel),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final family in ReaderFontFamily.values) ...[
                            if (family != ReaderFontFamily.values.first) const SizedBox(width: 10),
                            Expanded(
                              child: _FontTile(
                                family: family,
                                selected: provider.fontFamily == family,
                                onTap: () => provider.setFontFamily(family),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Size / line spacing / brightness / eye care —
                      // vertical "fill level" tiles: drag or tap inside a tile
                      // to set its value, the coloured band tracks it live and
                      // the number at the top reads out the current value.
                      // Expanded (not fixed-width) so all four fit side by side
                      // on narrow phones without overflowing.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LevelTile(
                              iconBuilder: (c) => Text(
                                'Aa',
                                style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w800),
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
                            child: _LevelTile(
                              iconBuilder: (c) =>
                                  HugeIcon(icon: HugeIcons.strokeRoundedLeftToRightListDash, color: c, size: 20),
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
                            child: _LevelTile(
                              iconBuilder: (c) => HugeIcon(icon: HugeIcons.strokeRoundedSun01, color: c, size: 20),
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
                            child: _LevelTile(
                              iconBuilder: (c) => HugeIcon(icon: HugeIcons.strokeRoundedEye, color: c, size: 20),
                              label: ReaderStrings.eyeCareLabel,
                              valueText: provider.eyeCare <= 0.0 ? '0%' : '${(provider.eyeCare * 100).round()}%',
                              value: provider.eyeCare,
                              min: 0.0,
                              max: 1.0,
                              onChanged: provider.setEyeCare,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Page transition (TZ §12.2) — opens its own sheet ─
                      const PageTransitionRow(),

                      // ── Fall back to the original PDF pages ────────────
                      // Only for a book that's actually a PDF reflowed into
                      // this reader — an escape hatch for a source file
                      // whose font/text encoding turns some sentences into
                      // gibberish once extracted, even though the real page
                      // (a picture, not text) still renders correctly.
                      if (showOriginalPdfOption) ...[
                        const SizedBox(height: 10),
                        _OriginalPdfRow(onTap: () => Navigator.pop(context, true)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.grey2, fontSize: 12.5, fontWeight: FontWeight.w600),
    );
  }
}

/// iOS-style theme swatch: just the page colour, no label — the selected one
/// carries a ring plus a checkmark instead.
class _ThemeButton extends StatelessWidget {
  final ReaderThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({required this.mode, required this.selected, required this.onTap});

  // The swatch keeps its own fixed reader-page colour regardless of app theme.
  Color get bgColor => switch (mode) {
        ReaderThemeMode.white => Colors.white,
        ReaderThemeMode.sepia => const Color(0xFFf5ebda),
        ReaderThemeMode.dark => const Color(0xFF1C1C1E),
        ReaderThemeMode.black => Colors.black,
      };

  // Contrasting colour for the checkmark against this swatch's own fill.
  Color get checkColor => switch (mode) {
        ReaderThemeMode.white || ReaderThemeMode.sepia => Colors.black87,
        _ => Colors.white,
      };

  String get semanticLabel => switch (mode) {
        ReaderThemeMode.white => ReaderStrings.themeWhite,
        ReaderThemeMode.sepia => ReaderStrings.themeSepia,
        ReaderThemeMode.dark => ReaderStrings.themeDark,
        ReaderThemeMode.black => ReaderStrings.themeBlack,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: selected ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: checkColor, size: 18) : null,
        ),
      ),
    );
  }
}

/// One font option, styled to match the level tiles below: a big "Aa" preview
/// rendered in the actual typeface over the font's name. Filled accent when
/// selected, outlined when idle.
class _FontTile extends StatelessWidget {
  final ReaderFontFamily family;
  final bool selected;
  final VoidCallback onTap;

  const _FontTile({required this.family, required this.selected, required this.onTap});

  String get name => switch (family) {
        ReaderFontFamily.sanFrancisco => 'San Francisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'Noto Serif',
        ReaderFontFamily.openSans => 'Open Sans',
      };

  String get fontFamily => switch (family) {
        ReaderFontFamily.sanFrancisco => 'SanFrancisco',
        ReaderFontFamily.arial => 'Arial',
        ReaderFontFamily.notoSerif => 'NotoSerif',
        ReaderFontFamily.openSans => 'OpenSans',
      };

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: TextStyle(color: fg, fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.grey2,
                fontSize: 10,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A vertical "fill level" control (TZ §12.4 reference design): a rounded
/// tile whose bottom band fills to the current value, with the icon pinned at
/// the bottom of the tile. Drag or tap anywhere in the tile to set a new
/// value — there's no separate slider track, the tile *is* the slider.
class _LevelTile extends StatelessWidget {
  final Widget Function(Color color) iconBuilder;
  final String label;

  /// Current value read out as text at the top of the tile (e.g. "20", "1.5",
  /// "100%"), so the reader can see the exact setting, not just the fill band.
  final String? valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LevelTile({
    required this.iconBuilder,
    required this.label,
    this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  static const _height = 120.0;
  // Narrower than the row slot it sits in (each tile is inside an Expanded),
  // and centred there — a full-width tile per slot read as too wide/blocky.
  static const _width = 58.0;
  // The icon sits in this bottom band; once the fill rises past it the icon
  // reads white (sitting on the accent), otherwise it stays muted.
  static const _iconBandHeight = 40.0;
  // The value readout sits in this top band; once the fill rises high enough
  // to reach it, its text flips to white the same way the icon does.
  static const _valueBandHeight = 28.0;

  double get _fraction => ((value - min) / (max - min)).clamp(0.0, 1.0);

  void _handle(Offset localPosition) {
    final frac = (1 - (localPosition.dy / _height)).clamp(0.0, 1.0);
    onChanged(min + frac * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    final fillHeight = _height * _fraction;
    // White while the fill covers the icon band, muted while it's above it.
    final iconOnFill = fillHeight >= _iconBandHeight * 0.6;
    // The value badge sits at the top, so the fill only reaches it near full.
    final valueOnFill = fillHeight >= (_height - _valueBandHeight * 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handle(d.localPosition),
          onVerticalDragUpdate: (d) => _handle(d.localPosition),
          // A border (plus the rounded corners) keeps the tile's outline
          // visible in both themes — otherwise the empty part is invisible
          // on the light sheet, where the card fill is white on white.
          child: Container(
            height: _height,
            width: _width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: fillHeight,
                  child: ColoredBox(color: AppColors.primary),
                ),
                // Value readout pinned at the top of the tile.
                if (valueText != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: _valueBandHeight,
                    child: Center(
                      child: Text(
                        valueText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: valueOnFill ? Colors.white : AppColors.grey1,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Icon fixed at the bottom of the tile.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _iconBandHeight,
                  child: Center(child: iconBuilder(iconOnFill ? Colors.white : AppColors.grey2)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Fixed two-line height so a one-line label ("Parlaklyk") reserves the
        // same space as a two-line one ("Şrift ölçegi") — keeps every tile the
        // same total height and aligned.
        SizedBox(
          height: 26,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.grey2, fontSize: 10.5, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ),
      ],
    );
  }
}

/// The "view original PDF pages" row — same card shape as [PageTransitionRow]
/// but a one-shot action rather than a row that opens a submenu: tapping it
/// pops the whole settings sheet with `true`, which [ReaderScreen] reads to
/// swap over to [PdfReaderScreen].
class _OriginalPdfRow extends StatelessWidget {
  final VoidCallback onTap;
  const _OriginalPdfRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedFile02, color: AppColors.primary, size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReaderStrings.pdfOriginalViewLabel,
                      style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ReaderStrings.pdfOriginalViewHint,
                      style: TextStyle(color: AppColors.grey2, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.grey3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
