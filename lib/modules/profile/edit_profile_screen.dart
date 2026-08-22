import 'package:flutter/material.dart';
import '../../core/localization/strings/profile_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import 'widgets/avatar_picker_sheet.dart';
import 'widgets/edit_profile_avatar_section.dart';
import 'widgets/edit_profile_fields.dart';
import 'widgets/edit_profile_save_button.dart';

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
  bool _saving = false;

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
      _nameController.text = (name != null && name.isNotEmpty)
          ? name
          : ProfileStrings.defaultReaderName;
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
    if (_saving) return;
    final name = _nameController.text.trim();
    final finalName = name.isEmpty ? ProfileStrings.defaultReaderName : name;
    setState(() => _saving = true);

    await AuthSession.saveName(finalName);
    await AuthSession.saveAvatar(_avatarIndex);
    if (_avatarImage != null) {
      await AuthSession.saveAvatarImage(_avatarImage!);
    } else {
      await AuthSession.clearAvatarImage();
    }

    // Local storage above is already what the rest of the app reads from,
    // so a backend failure here (offline, ...) shouldn't trap the user on
    // this screen — it's surfaced but the edit still stands locally.
    try {
      await AuthApiService.updateUsername(username: finalName);
      // Only the picked-photo case has a real image to push — a preset
      // avatar is a purely local concept the backend has no field for.
      if (_avatarImage != null) {
        await AuthApiService.updateImage(imageBase64: _avatarImage!);
      }
    } on ApiException catch (e) {
      if (mounted) context.showAppSnackBar(e.message, isError: true);
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
        title: Text(ProfileStrings.editProfileTitle,
            style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  EditProfileAvatarSection(
                    avatarIndex: _avatarIndex,
                    avatarImage: _avatarImage,
                    onTap: _pickAvatar,
                  ),
                  const SizedBox(height: 28),
                  EditProfileFields(
                      nameController: _nameController, phone: _phone),
                  const SizedBox(height: 32),
                  EditProfileSaveButton(
                    saving: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
      ),
    );
  }
}
