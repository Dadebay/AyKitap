import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/reader_provider.dart';
import '../../../core/localization/strings/reader_strings.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Theme ──────────────────────────────────────────────────
              Text(ReaderStrings.backgroundColorLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

              const SizedBox(height: 20),

              // ── Font size ──────────────────────────────────────────────
              Text(ReaderStrings.fontSizeLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Row(
                children: [
                  const Icon(Icons.text_decrease, color: Colors.white54, size: 18),
                  Expanded(
                    child: Slider(
                      value: provider.fontSize,
                      min: 12.0,
                      max: 28.0,
                      divisions: 8,
                      label: provider.fontSize.toStringAsFixed(0),
                      activeColor: const Color(0xFFE86B2C),
                      onChanged: provider.setFontSize,
                    ),
                  ),
                  const Icon(Icons.text_increase, color: Colors.white54, size: 18),
                ],
              ),

              const SizedBox(height: 12),

              // ── Font family ────────────────────────────────────────────
              Text(ReaderStrings.fontLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReaderFontFamily.values.map((family) {
                  return _FontButton(
                    family: family,
                    selected: provider.fontFamily == family,
                    onTap: () => provider.setFontFamily(family),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Line spacing ───────────────────────────────────────────
              Text(ReaderStrings.lineSpacingLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Row(
                children: [
                  const Icon(Icons.format_line_spacing, color: Colors.white54, size: 18),
                  Expanded(
                    child: Slider(
                      value: provider.lineSpacing,
                      min: 1.0,
                      max: 2.5,
                      divisions: 6,
                      activeColor: const Color(0xFFE86B2C),
                      onChanged: provider.setLineSpacing,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final ReaderThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeButton({required this.mode, required this.selected, required this.onTap});

  Color get bgColor => switch (mode) {
        ReaderThemeMode.white => Colors.white,
        ReaderThemeMode.sepia => const Color(0xFFf5ebda),
        ReaderThemeMode.dark => const Color(0xFF1C1C1E),
        ReaderThemeMode.black => Colors.black,
      };

  Color get textColor => switch (mode) {
        ReaderThemeMode.white || ReaderThemeMode.sepia => Colors.black87,
        _ => Colors.white,
      };

  String get label => switch (mode) {
        ReaderThemeMode.white => ReaderStrings.themeWhite,
        ReaderThemeMode.sepia => ReaderStrings.themeSepia,
        ReaderThemeMode.dark => ReaderStrings.themeDark,
        ReaderThemeMode.black => ReaderStrings.themeBlack,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFE86B2C) : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 12)),
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
        ReaderFontFamily.sfPro => 'SF Pro',
        ReaderFontFamily.newYork => 'New York',
        ReaderFontFamily.gilroy => 'Gilroy',
      };

  String get fontFamily => switch (family) {
        ReaderFontFamily.sfPro => 'SFPro',
        ReaderFontFamily.newYork => 'NewYork',
        ReaderFontFamily.gilroy => 'Gilroy',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE86B2C) : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }
}
