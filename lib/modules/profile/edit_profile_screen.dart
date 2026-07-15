import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_session.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/localization/strings/profile_strings.dart';

/// Standalone "edit profile" page (avatar + ulanyjy ady) — pushed as its own
/// route rather than living inline on the Profile tab, so leaving it
/// behaves like any other sub-page (back button, own history entry)
/// instead of mutating the tab in place.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  int _avatarIndex = -1;
  String? _avatarImage;
  String _phone = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await AuthSession.getName();
    final avatar = await AuthSession.getAvatar();
    final avatarImage = await AuthSession.getAvatarImage();
    final phone = await AuthSession.getPhone();
    if (!mounted) return;
    setState(() {
      _nameController.text = (name != null && name.isNotEmpty) ? name : ProfileStrings.defaultReaderName;
      _avatarIndex = avatar;
      _avatarImage = avatarImage;
      _phone = phone ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await showModalBottomSheet<_AvatarPickResult>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AvatarPickerSheet(current: _avatarIndex),
    );
    if (result == null) return;
    setState(() {
      if (result.imageBase64 != null) {
        _avatarImage = result.imageBase64;
        _avatarIndex = -1;
      } else {
        _avatarIndex = result.presetIndex!;
        _avatarImage = null;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    await AuthSession.saveName(name.isEmpty ? ProfileStrings.defaultReaderName : name);
    await AuthSession.saveAvatar(_avatarIndex);
    if (_avatarImage != null) {
      await AuthSession.saveAvatarImage(_avatarImage!);
    } else {
      await AuthSession.clearAvatarImage();
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(ProfileStrings.editProfileTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        ProfileAvatar(index: _avatarIndex, size: 96, imageBase64: _avatarImage),
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
                            child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Colors.white, size: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(ProfileStrings.usernameLabel, style: TextStyle(color: AppColors.grey2, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _nameController,
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
                Text(ProfileStrings.phoneNumberLabel, style: TextStyle(color: AppColors.grey2, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: Text(_phone, style: TextStyle(color: AppColors.grey2, fontSize: 15)),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    onPressed: _save,
                    child: Text(ProfileStrings.save, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Either a preset avatar index or a custom photo the user picked.
class _AvatarPickResult {
  final int? presetIndex;
  final String? imageBase64;
  const _AvatarPickResult.preset(int index)
      : presetIndex = index,
        imageBase64 = null;
  const _AvatarPickResult.image(String base64)
      : presetIndex = null,
        imageBase64 = base64;
}

/// Bottom sheet: pick a photo from the device, or fall back to one of the
/// preset avatars (TZ 8.1). Returns an [_AvatarPickResult].
class _AvatarPickerSheet extends StatefulWidget {
  final int current;
  const _AvatarPickerSheet({required this.current});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  bool _picking = false;

  Future<void> _pickOwnPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      if (mounted) Navigator.pop(context, _AvatarPickResult.image(base64Encode(bytes)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ProfileStrings.imageNotSelected(e))));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  onTap: () => Navigator.pop(context, _AvatarPickResult.preset(i)),
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
    );
  }
}
