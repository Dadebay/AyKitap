import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/auth_strings.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/primary_button.dart';

/// Shown once, right after a first-time signup completes its OTP step —
/// the account needs a display name and there's no way past this screen
/// without giving one (no back arrow, no skip).
class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;

  bool get _isValid => _nameController.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isValid || _saving) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    try {
      // The bearer token is already in secure storage by the time this
      // screen shows (OtpVerifyScreen saves it before pushing here), so
      // this PATCH lands on the account that was just created — the
      // backend has a `username` on file the moment the account does,
      // not just this device's local copy of it.
      await AuthApiService.updateUsername(username: name);
      if (!mounted) return;
      Navigator.pop(context, name);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const GradientIconBadge(icon: HugeIcons.strokeRoundedUser),
                const SizedBox(height: 24),
                Text(AuthStrings.nameEntryTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  AuthStrings.nameEntrySubtitle,
                  style: TextStyle(
                      color: AppColors.grey2, fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  label: AuthStrings.nameLabel,
                  hint: AuthStrings.nameHint,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  leadingIcon: HugeIcons.strokeRoundedUser,
                  onSubmitted: (_) => _continue(),
                ),
                const Spacer(),
                PrimaryButton(
                    label: AuthStrings.continueButton,
                    loading: _saving,
                    onPressed: _isValid ? _continue : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
