import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/strings/reader_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/widgets/settings_tiles.dart' show AppSwitch;
import '../utils/reader_orientation.dart';

/// The "Ýatyk okamak" row — reading with the phone turned sideways.
///
/// Appears in all three readers' settings sheets ([ReaderSettingsSheet],
/// [PdfSettingsSheet], [CbzSettingsSheet]). The setting itself is app-wide,
/// so putting it in only one of them would hide it from whoever happens to be
/// reading a PDF or a comic — they'd have to open an EPUB to find a switch
/// that governs the book already in front of them.
///
/// A switch rather than a row that opens its own sheet (the shape
/// [PageTransitionRow] uses) because there are only two states, and because
/// the effect is immediate and visible behind the sheet: flipping it turns
/// the book under the reader's thumb, so a second popup to confirm a choice
/// they can already see would only be in the way.
///
/// The reader *may* already turn the phone by hand — landscape has always
/// been allowed while a reader is open. This exists for the phone whose
/// system rotation lock is on, which never leaves portrait however it is
/// held; see [AppOrientationPolicy.setReaderActive] for how the choice is
/// actually enforced.
///
/// It owns its own state rather than reading a provider, because two of the
/// three sheets have no [ReaderProvider] above them — the PDF and CBZ readers
/// are plain screens holding their own settings. One switch, one stored
/// value, read straight from where [setReaderLandscapeReading] writes it.
class ReaderLandscapeRow extends StatefulWidget {
  const ReaderLandscapeRow({super.key});

  @override
  State<ReaderLandscapeRow> createState() => _ReaderLandscapeRowState();
}

class _ReaderLandscapeRowState extends State<ReaderLandscapeRow> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _enabled = prefs.getBool(readerLandscapePrefKey) ?? false);
  }

  Future<void> _set(bool enabled) async {
    // Moves under the thumb first, waits for the disk afterwards — the switch
    // is the one part of this whose latency the reader would notice.
    setState(() => _enabled = enabled);
    await setReaderLandscapeReading(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _set(!_enabled),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSmartPhoneLandscape,
                  color: AppColors.primary,
                  size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ReaderStrings.landscapeReadingTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              // The app's own pill switch (Profile > Sazlamalar uses it too)
              // rather than a Material [Switch], so the reader's settings
              // don't introduce a second toggle shape.
              AppSwitch(value: _enabled, onChanged: _set),
            ],
          ),
        ),
      ),
    );
  }
}
