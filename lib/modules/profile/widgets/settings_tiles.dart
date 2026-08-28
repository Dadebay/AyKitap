import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class NavTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? value;
  final Widget? leadingValue;
  final bool danger;
  final VoidCallback onTap;
  const NavTile(
      {super.key,
      required this.icon,
      required this.label,
      this.value,
      this.leadingValue,
      this.danger = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: HugeIcon(icon: icon, color: color, size: 20),
      title: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: danger ? Colors.redAccent : AppColors.grey1,
              fontSize: 14.5,
              fontWeight: FontWeight.w600)),
      trailing: value != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              if (leadingValue != null) ...[
                leadingValue!,
                const SizedBox(width: 8)
              ],
              Text(value!,
                  style: TextStyle(color: AppColors.grey2, fontSize: 13)),
              const SizedBox(width: 6),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.grey3,
                  size: 16),
            ])
          : null,
    );
  }
}

class SwitchTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool switchValue;
  final ValueChanged<bool> onChanged;

  /// Replaces the default sun/moon [ThemeSwitch]. Only the theme row wants
  /// glyphs riding in the thumb; every other row uses the plain [AppSwitch],
  /// and passing the control in keeps this tile from having to know which
  /// row it is.
  final Widget? control;

  const SwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.switchValue,
    required this.onChanged,
    this.control,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: iconColor, size: 22),
      title: Text(label,
          style: TextStyle(
              color: AppColors.grey1,
              fontSize: 14.5,
              fontWeight: FontWeight.w600)),
      trailing:
          control ?? ThemeSwitch(isDark: switchValue, onChanged: onChanged),
      subtitle:
          Text(value, style: TextStyle(color: AppColors.grey2, fontSize: 12)),
    );
  }
}

/// The same pill as [ThemeSwitch] without the sun/moon glyph — for rows that
/// are a plain on/off rather than a choice between two modes.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Greys the pill out and ignores taps while a change is in flight — a
  /// permission prompt is a round trip through the OS, and a switch that
  /// still moves under your finger during it is lying about the state.
  final bool enabled;

  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 54,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: value ? AppColors.primary : AppColors.grey3,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped toggle with a sun/moon glyph riding inside the thumb,
/// instead of a generic Material [Switch] — reads at a glance which mode
/// is active without needing the subtitle text.
class ThemeSwitch extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const ThemeSwitch({super.key, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 54,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF352E5C), Color(0xFF201A38)]
                : const [Color(0xFFFFD27A), Color(0xFFFFA726)],
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: HugeIcon(
                icon: isDark
                    ? HugeIcons.strokeRoundedMoon02
                    : HugeIcons.strokeRoundedSun03,
                color:
                    isDark ? const Color(0xFF8B7BF0) : const Color(0xFFFFA726),
                size: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
