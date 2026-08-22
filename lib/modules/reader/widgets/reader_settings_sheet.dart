import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/reader_provider.dart';
import 'page_transition_section.dart';
import 'reader_appearance_levels_row.dart';
import 'reader_font_tile.dart';
import 'reader_original_pdf_row.dart';
import 'reader_section_label.dart';
import 'reader_sheet_header.dart';
import 'reader_theme_button.dart';

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
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                closeIcon: Icon(Icons.keyboard_arrow_down,
                    color: AppColors.grey2, size: 22),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Theme (iOS-style: colour only, check = selected) ─
                      ReaderSectionLabel(ReaderStrings.backgroundColorLabel),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ReaderThemeMode.values.map((mode) {
                          return ReaderThemeButton(
                            mode: mode,
                            selected: provider.themeMode == mode,
                            onTap: () => provider.setTheme(mode),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // ── Font family — a row of four preview tiles ──────
                      ReaderSectionLabel(ReaderStrings.fontLabel),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final family in ReaderFontFamily.values) ...[
                            if (family != ReaderFontFamily.values.first)
                              const SizedBox(width: 10),
                            Expanded(
                              child: ReaderFontTile(
                                family: family,
                                selected: provider.fontFamily == family,
                                onTap: () => provider.setFontFamily(family),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Size / line spacing / brightness / eye care ────
                      ReaderAppearanceLevelsRow(provider: provider),

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
                        ReaderOriginalPdfRow(
                            onTap: () => Navigator.pop(context, true)),
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
