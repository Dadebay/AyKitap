import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../theme/app_colors.dart';
import 'network_cover_image.dart';

/// A preset avatar ("awatarlar boil", TZ 8.1): a gradient disc with an emoji.
/// The app ships no avatar photos, so users pick from this fixed set instead
/// of uploading — the chosen index is persisted via AuthSession.
class ProfileAvatarData {
  final String emoji;
  final List<Color> gradient;
  const ProfileAvatarData(this.emoji, this.gradient);
}

const List<ProfileAvatarData> kProfileAvatars = [
  ProfileAvatarData('🦊', [Color(0xFFF7971E), Color(0xFFFFD200)]),
  ProfileAvatarData('🦉', [Color(0xFF4E54C8), Color(0xFF8F94FB)]),
  ProfileAvatarData('🐼', [Color(0xFF485563), Color(0xFF29323C)]),
  ProfileAvatarData('🐧', [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
  ProfileAvatarData('🦁', [Color(0xFFF12711), Color(0xFFF5AF19)]),
  ProfileAvatarData('🐨', [Color(0xFF757F9A), Color(0xFFD7DDE8)]),
  ProfileAvatarData('🐯', [Color(0xFFFF8008), Color(0xFFFFC837)]),
  ProfileAvatarData('🐰', [Color(0xFFEE9CA7), Color(0xFFFFDDE1)]),
  ProfileAvatarData('🦄', [Color(0xFFDA22FF), Color(0xFF9733EE)]),
  ProfileAvatarData('🐻', [Color(0xFF603813), Color(0xFFB29F94)]),
  ProfileAvatarData('🐸', [Color(0xFF11998E), Color(0xFF38EF7D)]),
  ProfileAvatarData('🐙', [Color(0xFFEB3349), Color(0xFFF45C43)]),
];

/// Renders avatar [index] from [kProfileAvatars], or a neutral placeholder
/// disc when [index] is out of range (no avatar chosen yet). When
/// [imageBase64] is set (the user picked their own photo on this device but
/// hasn't necessarily synced it yet) it's shown instead, taking priority
/// over both [imageUrl] and the preset index. [imageUrl] (the backend's
/// `/users/me` `image`) is the next fallback — shown when there's no local
/// pick to prefer, e.g. right after a fresh install on a second device.
class ProfileAvatar extends StatelessWidget {
  final int index;
  final double size;
  final String? imageBase64;
  final String? imageUrl;
  const ProfileAvatar({super.key, required this.index, this.size = 88, this.imageBase64, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          base64Decode(imageBase64!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        // A broken/unreachable URL shouldn't take the whole avatar down —
        // falls back to the same placeholder an unset avatar gets.
        child: NetworkCoverImage(url: imageUrl!, width: size, height: size, placeholder: (_) => _placeholder()),
      );
    }
    if (index < 0 || index >= kProfileAvatars.length) {
      return _placeholder();
    }
    final avatar = kProfileAvatars[index];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: avatar.gradient),
      ),
      child: Center(child: Text(avatar.emoji, style: TextStyle(fontSize: size * 0.5))),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey2, size: size * 0.45)),
    );
  }
}
