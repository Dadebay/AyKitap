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
  const ReaderSettingsSheet({super.key});

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

                      // ── Font family ────────────────────────────────────
                      _SectionLabel(ReaderStrings.fontLabel),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ReaderFontFamily.values.map((family) {
                          return _FontButton(
                            family: family,
                            selected: provider.fontFamily == family,
                            onTap: () => provider.setFontFamily(family),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // ── Size / line spacing / brightness — vertical
                      // "fill level" tiles: drag or tap inside a tile to set
                      // its value, the coloured band tracks it live.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _LevelTile(
                            iconBuilder: (c) => Text(
                              'Aa',
                              style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            label: ReaderStrings.fontSizeLabel,
                            value: provider.fontSize,
                            min: 12.0,
                            max: 28.0,
                            onChanged: provider.setFontSize,
                          ),
                          _LevelTile(
                            iconBuilder: (c) =>
                                HugeIcon(icon: HugeIcons.strokeRoundedLeftToRightListDash, color: c, size: 20),
                            label: ReaderStrings.lineSpacingLabel,
                            value: provider.lineSpacing,
                            min: 1.0,
                            max: 2.5,
                            onChanged: provider.setLineSpacing,
                          ),
                          _LevelTile(
                            iconBuilder: (c) => HugeIcon(icon: HugeIcons.strokeRoundedSun01, color: c, size: 20),
                            label: ReaderStrings.brightnessLabel,
                            value: provider.brightness,
                            min: 0.1,
                            max: 1.0,
                            onChanged: provider.setBrightness,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Page transition (TZ §12.2) — opens its own sheet ─
                      const PageTransitionRow(),
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

class _FontButton extends StatelessWidget {
  final ReaderFontFamily family;
  final bool selected;
  final VoidCallback onTap;

  const _FontButton({required this.family, required this.selected, required this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 1),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
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
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LevelTile({
    required this.iconBuilder,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  static const _height = 120.0;
  static const _width = 74.0;
  // The icon sits in this bottom band; once the fill rises past it the icon
  // reads white (sitting on the accent), otherwise it stays muted.
  static const _iconBandHeight = 40.0;

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

    return SizedBox(
      width: _width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handle(d.localPosition),
            onVerticalDragUpdate: (d) => _handle(d.localPosition),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: _height,
                width: _width,
                child: Stack(
                  children: [
                    ColoredBox(color: AppColors.card),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: fillHeight,
                      child: ColoredBox(color: AppColors.primary),
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
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.grey2, fontSize: 10.5, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}
