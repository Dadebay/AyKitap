import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/profile_avatar.dart';

/// [EditProfileScreen]'s tappable avatar circle + camera badge — split out
/// to keep that file under the 200-line limit.
class EditProfileAvatarSection extends StatelessWidget {
  final int avatarIndex;
  final String? avatarImage;
  final VoidCallback onTap;

  const EditProfileAvatarSection({
    super.key,
    required this.avatarIndex,
    required this.avatarImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ProfileAvatar(
                index: avatarIndex, size: 96, imageBase64: avatarImage),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
                child: const Center(
                    child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        color: Colors.white,
                        size: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
