import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/auth_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/primary_button.dart';
import 'otp_verify_screen.dart';

/// Hasap Açmak / Giriş — TZ section 2.1, 2.3.
/// A single phone-number entry screen serves both registration and login:
/// the backend decides which one it is once the OTP is verified.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer(debugOwner: this)..onTap = _openTerms;

  static final Uri _termsUrl = Uri.parse('https://ayterek.com/ru/general-rules');

  Future<void> _openTerms() async {
    await launchUrl(_termsUrl, mode: LaunchMode.externalApplication);
  }

  // Demo-only toggle so the "already logged in elsewhere" flow (TZ 2.2) can
  // be shown without a real backend behind it.
  bool _simulateOtherDevice = false;
  bool _sending = false;

  static const _digitsNeeded = 8; // XX XX XX XX

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get _isValid => _digits.length == _digitsNeeded;

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  String _formatPhone(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i % 2 == 1 && i != digits.length - 1) buf.write(' ');
    }
    return buf.toString();
  }

  void _onPhoneChanged(String value) {
    final allDigits = value.replaceAll(RegExp(r'\D'), '');
    final digits = allDigits.substring(0, allDigits.length.clamp(0, _digitsNeeded));
    final formatted = _formatPhone(digits);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  Future<void> _sendCode() async {
    if (!_isValid || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 700)); // mock network
    if (!mounted) return;
    setState(() => _sending = false);

    final loggedIn = await context.push<bool>(
      OtpVerifyScreen(phone: '+993 ${_phoneController.text}', simulateOtherDevice: _simulateOtherDevice),
    );
    if (loggedIn == true && mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom - MediaQuery.of(context).padding.vertical - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBackButton(),
                const SizedBox(height: 12),
                const GradientIconBadge(icon: HugeIcons.strokeRoundedSmartPhone01),
                const SizedBox(height: 24),
                Text(
                  AuthStrings.phoneLoginTitle,
                  style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  AuthStrings.phoneLoginSubtitle,
                  style: TextStyle(color: AppColors.grey2, fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _phoneController,
                  focusNode: _focusNode,
                  label: AuthStrings.phoneNumberLabel,
                  hint: AuthStrings.phoneHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  style: TextStyle(color: AppColors.white, fontSize: 16, letterSpacing: 1),
                  onChanged: _onPhoneChanged,
                  prefix: Row(
                    children: [
                      const Text('🇹🇲', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('+993', style: TextStyle(color: AppColors.grey1, fontSize: 16, fontWeight: FontWeight.w600)),
                      Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 1, height: 22, color: AppColors.border),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Demo-only: lets you preview the "logged in on another device"
                // dialog (TZ 2.2) without a real second session.
                InkWell(
                  onTap: () => setState(() => _simulateOtherDevice = !_simulateOtherDevice),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: _simulateOtherDevice ? HugeIcons.strokeRoundedCheckmarkCircle01 : HugeIcons.strokeRoundedCircle,
                          color: _simulateOtherDevice ? AppColors.primary : AppColors.grey3,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AuthStrings.simulateOtherDeviceLabel,
                            style: TextStyle(color: AppColors.grey3, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: AuthStrings.sendCodeButton, loading: _sending, onPressed: _isValid ? _sendCode : null),
                const SizedBox(height: 14),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: AppColors.grey3, fontFamily: 'GilroyRegular', fontSize: 11.5),
                    children: [
                      TextSpan(text: AuthStrings.termsPrefix),
                      TextSpan(
                        text: AuthStrings.termsLink,
                        style: TextStyle(color: AppColors.primary, fontFamily: 'GilroyRegular', fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                        recognizer: _termsTap,
                      ),
                      TextSpan(text: AuthStrings.termsSuffix),
                    ],
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
