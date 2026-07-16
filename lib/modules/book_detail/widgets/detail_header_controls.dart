import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/icon_circle_button.dart';

/// The back / mark-finished / favorite / share row from Book Detail's hero
/// (§10.1.3–4). Kept separate from [DetailHeaderArt] so the caller can pin
/// it as its own top-most layer — a plain [Stack] with the scrolling
/// content sheet in the middle would otherwise let the sheet's scroll
/// gesture area swallow taps meant for these buttons whenever it scrolls
/// up over the header art.
class DetailHeaderControls extends StatelessWidget {
  const DetailHeaderControls({
    super.key,
    required this.isFinished,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFinished,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final bool isFinished;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFinished;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topPad + 8, left: 12, right: 12),
      child: Row(
        children: [
          _overlayIcon(HugeIcons.strokeRoundedArrowLeft01, onTap: onBack),
          const Spacer(),
          _overlayIcon(HugeIcons.strokeRoundedFlag02, active: isFinished, onTap: onToggleFinished),
          const SizedBox(width: 8),
          _overlayIcon(HugeIcons.strokeRoundedFavourite, active: isFavorite, onTap: onToggleFavorite),
          const SizedBox(width: 8),
          _overlayIcon(HugeIcons.strokeRoundedShare08, onTap: onShare),
        ],
      ),
    );
  }

  Widget _overlayIcon(List<List<dynamic>> icon, {bool active = false, required VoidCallback onTap}) {
    return IconCircleButton(
      icon: icon,
      onTap: onTap,
      size: 38,
      iconSize: 18,
      backgroundColor: Colors.black.withValues(alpha: 0.35),
      iconColor: active ? AppColors.primary : Colors.white,
    );
  }
}
