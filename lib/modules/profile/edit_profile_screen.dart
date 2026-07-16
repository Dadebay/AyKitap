import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_session.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/localization/strings/profile_strings.dart';
import 'widgets/avatar_picker_sheet.dart';

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
    final result = await showModalBottomSheet<AvatarPickResult>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AvatarPickerSheet(current: _avatarIndex),
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
        leading: const AppBackButton(size: 20),
        centerTitle: true,
        title: Text(ProfileStrings.editProfileTitle, style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: _loading
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
      ),
    );
  }
}
