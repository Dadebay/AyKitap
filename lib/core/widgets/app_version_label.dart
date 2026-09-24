import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../localization/strings/settings_strings.dart';
import '../theme/app_colors.dart';

/// "Aykitap v1.1.5 (15)" — read from the installed build.
///
/// Asynchronous because that is the only way to know it: the number lives in
/// the platform's own bundle metadata, not in Dart. Renders nothing until it
/// arrives, which is a blank line at the very bottom of Settings for a frame
/// or two and better than showing a placeholder that might be wrong.
class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({super.key});

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() =>
          _label = SettingsStrings.appVersion(info.version, info.buildNumber));
    } catch (_) {
      // No bundle metadata to read — a widget test with no plugin behind the
      // channel, or a platform the plugin doesn't cover. The line simply
      // stays empty; nothing else on this screen depends on it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label == null) return const SizedBox(height: 15);
    return Text(label, style: TextStyle(color: AppColors.grey3, fontSize: 12));
  }
}
