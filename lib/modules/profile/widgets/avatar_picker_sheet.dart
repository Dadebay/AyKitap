import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/localization/strings/profile_strings.dart';

/// Either a preset avatar index or a custom photo the user picked.
class AvatarPickResult {
  final int? presetIndex;
  final String? imageBase64;
  const AvatarPickResult.preset(int index)
      : presetIndex = index,
        imageBase64 = null;
  const AvatarPickResult.image(String base64)
      : presetIndex = null,
        imageBase64 = base64;
}

/// Bottom sheet: pick a photo from the device, or fall back to one of the
/// preset avatars (TZ 8.1). Returns an [AvatarPickResult].
class AvatarPickerSheet extends StatefulWidget {
  final int current;
  const AvatarPickerSheet({super.key, required this.current});

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  bool _picking = false;

  Future<void> _pickOwnPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      // Shrink to the backend's 1 MB avatar upload limit before it ever
      // reaches the base64 encode — a raw gallery photo routinely exceeds it.
      final compressed = ImageCompressor.compress(bytes) ?? bytes;
      if (mounted) Navigator.pop(context, AvatarPickResult.image(base64Encode(compressed)));
    } catch (e) {
      if (mounted) context.showAppSnackBar(ProfileStrings.imageNotSelected(e), isError: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(ProfileStrings.chooseAvatarTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickOwnPhoto,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: _picking
                            ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                            : Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppColors.primary, size: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(ProfileStrings.chooseOwnPhoto, style: TextStyle(color: AppColors.white, fontSize: 14.5, fontWeight: FontWeight.w600))),
                      HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey3, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(ProfileStrings.presetAvatars, style: TextStyle(color: AppColors.grey2, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kProfileAvatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemBuilder: (context, i) {
                  final selected = i == widget.current;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, AvatarPickResult.preset(i)),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: AppColors.primary, width: 3) : null,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ProfileAvatar(index: i, size: 60),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
