import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/strings/settings_strings.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'pressable_scale.dart';

/// Tells the reader a newer build is on the store, and offers to open it.
///
/// A sheet rather than a permanent banner: an update is worth interrupting
/// for once, not worth a strip of screen on every visit to Home. It appears
/// at most once per launch, and "Soňra" remembers *that* version — so
/// declining 1.2.1 stays declined until 1.2.2 ships, instead of asking again
/// on the next cold start. That is the difference between a reminder and
/// nagging, and nagging is what makes people stop reading these.
class UpdateAvailableSheet extends StatelessWidget {
  const UpdateAvailableSheet({super.key, required this.release});

  final StoreRelease release;

  /// The version the reader last said "Soňra" to.
  static const _skippedVersionKey = 'update_skipped_version';

  /// Checks the store and, if there is something newer that hasn't already
  /// been declined, shows the sheet. Safe to call and forget: every failure
  /// path inside [AppUpdateService] returns null, so a blocked or slow
  /// network simply means no sheet.
  static Future<void> maybeShow(BuildContext context) async {
    updateDebugLog('Check starting (after the notification prompt)');
    final release = await AppUpdateService.instance.check();
    if (release == null) return; // check() has already said why.
    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getString(_skippedVersionKey);
    if (skipped == release.version) {
      updateDebugLog(
        'Version ${release.version} was already declined with "Soňra" — '
        'no sheet. Clear the app data to see it again.',
        bad: true,
      );
      return;
    }
    if (skipped != null) {
      updateDebugLog('Previously declined $skipped, which is not this one');
    }
    if (!context.mounted) {
      updateDebugLog('Screen was gone before the answer arrived — no sheet',
          bad: true);
      return;
    }
    updateDebugLog('SHOWING THE SHEET', ok: true);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => UpdateAvailableSheet(release: release),
    );
  }

  Future<void> _later(BuildContext context) async {
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, release.version);
    updateDebugLog('"Soňra" — ${release.version} will not be offered again');
  }

  Future<void> _update(BuildContext context) async {
    Navigator.pop(context);
    updateDebugLog('"Täzele" — opening ${release.storeUrl}', ok: true);
    // externalApplication so it lands in the actual store app rather than an
    // in-app browser, where the install button doesn't work.
    await launchUrl(release.storeUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // clipBehavior so the gradient wash below is cut by those top corners
      // instead of painting square ones over them.
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // A soft tint bleeding down from the top edge, so the sheet reads as
          // part of the Journey palette rather than a plain grey panel. It
          // fades to transparent well before the buttons — a full-height wash
          // would tint the text and cost it contrast.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 190,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppGradients.journeyPrimaryColors[1]
                          .withValues(alpha: 0.13),
                      AppColors.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                22, 12, 22, 22 + MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _badge(),
                const SizedBox(height: 18),
                Text(
                  SettingsStrings.updateTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  SettingsStrings.updateSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey2,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _versionRow(),
                const SizedBox(height: 22),
                _updateButton(context),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: () => _later(context),
                    child: Text(
                      SettingsStrings.updateLater,
                      style: TextStyle(
                        color: AppColors.grey2,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The gradient disc, with the same sweep spilling underneath it as a soft
  /// shadow — the glow is the gradient's own middle stop, not a grey drop
  /// shadow, so the badge looks lit rather than lifted.
  Widget _badge() {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        gradient: AppGradients.journeyPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppGradients.journeyPrimaryColors[1].withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDownload04,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// "1.1.5 → 1.2.1" as two captioned chips.
  ///
  /// This is the part a sentence was doing badly: two version numbers inside
  /// a line of prose have to be read and compared word by word, while the
  /// same two numbers side by side with an arrow between them say "this one
  /// becomes that one" before anything is read at all. The new number is the
  /// one carrying the accent; the installed one is deliberately quiet.
  Widget _versionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _versionChip(
            caption: SettingsStrings.updateInstalledLabel,
            version: release.installedVersion,
            highlighted: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: AppColors.grey3,
            size: 20,
          ),
        ),
        Flexible(
          child: _versionChip(
            caption: SettingsStrings.updateStoreLabel,
            version: release.version,
            highlighted: true,
          ),
        ),
      ],
    );
  }

  Widget _versionChip({
    required String caption,
    required String version,
    required bool highlighted,
  }) {
    final accent = AppGradients.journeyPrimaryColors[1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withValues(alpha: 0.10)
            : AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? accent.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            caption.toUpperCase(),
            style: TextStyle(
              color: highlighted ? accent : AppColors.grey2,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            version,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlighted ? AppColors.white : AppColors.grey2,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              // Tabular figures so the two chips' digits line up with each
              // other instead of drifting by a hair per glyph width.
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// The primary action, painted with the full Journey sweep rather than the
  /// flat orange of [PrimaryButton]: this sheet interrupts a reader, so the
  /// one thing it is asking for should be unmistakably the brightest object
  /// on it. [PressableScale] gives it the same press feel (and haptic) as the
  /// app's cards, which an ElevatedButton's ripple does not.
  Widget _updateButton(BuildContext context) {
    return PressableScale(
      onTap: () => _update(context),
      pressedScale: 0.97,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppGradients.journeyPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  AppGradients.journeyPrimaryColors[1].withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: Text(
            SettingsStrings.updateNow,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
