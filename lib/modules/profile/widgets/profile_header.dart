import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/widgets/profile_avatar.dart';

/// The signed-out hero card: prompt + a "Giriş" button that starts the
/// phone-login flow.
class LoggedOutSection extends StatelessWidget {
  const LoggedOutSection({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.16), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: AppColors.grey2, size: 36)),
          ),
          const SizedBox(height: 18),
          Text(ProfileStrings.loginHeading, style: TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            ProfileStrings.loginBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
          ),
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.only(top: 24, bottom: 32),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              onPressed: onLogin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(icon: HugeIcons.strokeRoundedSmartPhone01, color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(ProfileStrings.login, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar (with an edit/camera badge) + name + masked phone, all tappable
/// to open [EditProfileScreen].
class ProfileTopSection extends StatelessWidget {
  const ProfileTopSection({
    super.key,
    required this.name,
    required this.maskedPhone,
    required this.avatarIndex,
    required this.avatarImage,
    required this.onTap,
  });

  final String name;
  final String maskedPhone;
  final int avatarIndex;
  final String? avatarImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              ProfileAvatar(index: avatarIndex, size: 88, imageBase64: avatarImage),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 2),
                  ),
                  child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Colors.white, size: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.grey3, size: 15),
            ],
          ),
        ),
        Text(maskedPhone, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
      ],
    );
  }
}
