import 'package:flutter/material.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/theme/app_colors.dart';

/// [EditProfileScreen]'s username input + read-only phone display — split
/// out to keep that file under the 200-line limit.
class EditProfileFields extends StatelessWidget {
  final TextEditingController nameController;
  final String phone;

  const EditProfileFields(
      {super.key, required this.nameController, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ProfileStrings.usernameLabel,
            style: TextStyle(
                color: AppColors.grey2,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: nameController,
            maxLength: 24,
            style: TextStyle(color: AppColors.white, fontSize: 15),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              hintText: ProfileStrings.usernameHint,
              hintStyle: TextStyle(color: AppColors.grey3),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(ProfileStrings.phoneNumberLabel,
            style: TextStyle(
                color: AppColors.grey2,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
              color: AppColors.card, borderRadius: BorderRadius.circular(14)),
          child: Text(phone,
              style: TextStyle(color: AppColors.grey2, fontSize: 15)),
        ),
      ],
    );
  }
}
