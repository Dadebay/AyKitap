import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/auth_strings.dart';

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
    _focusNode.addListener(() => setState(() {}));
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
    Navigator.pop(context, _nameController.text.trim());
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF77E68), Color(0xFFB44BE8)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: HugeIcon(icon: HugeIcons.strokeRoundedUser, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 24),
                Text(AuthStrings.nameEntryTitle, style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  AuthStrings.nameEntrySubtitle,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 32),
                Text(AuthStrings.nameLabel, style: TextStyle(color: AppColors.grey1, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _focusNode.hasFocus ? AppColors.primary : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedUser, color: _focusNode.hasFocus ? AppColors.primary : AppColors.grey3, size: 20),
                      Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 1, height: 22, color: AppColors.border),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          focusNode: _focusNode,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [LengthLimitingTextInputFormatter(40)],
                          style: TextStyle(color: AppColors.white, fontSize: 16),
                          decoration: InputDecoration(hintText: AuthStrings.nameHint, hintStyle: TextStyle(color: AppColors.grey3), border: InputBorder.none, isDense: true),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _continue(),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid ? AppColors.primary : AppColors.card,
                      disabledBackgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isValid ? _continue : null,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(
                            AuthStrings.continueButton,
                            style: TextStyle(color: _isValid ? Colors.white : AppColors.grey3, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
