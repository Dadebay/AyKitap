import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/contact_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/auth_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/or_divider.dart';
import '../../core/widgets/primary_button.dart';
import 'international_login_screen.dart';
import 'otp_verify_screen.dart';
import 'provider/auth_provider.dart';
import 'widgets/auth_provider_button.dart';

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
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer(debugOwner: this)..onTap = _openTerms;

  // Fetched on tap rather than on screen load — this link is rarely opened,
  // so there's no point in a `/contacts` call every time this screen shows.
  Future<void> _openTerms() async {
    try {
      final contacts = await ContactApiService.getContacts();
      final link = contacts.userAgreementLink;
      if (link == null || link.isEmpty) return;
      final uri = Uri.tryParse(link);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on ApiException catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.message, isError: true);
    }
  }

  // Demo-only toggle so the "already logged in elsewhere" flow (TZ 2.2) can
  // be shown without a real backend behind it.
  bool _simulateOtherDevice = false;
  final _authProvider = AuthProvider();

  static const _digitsNeeded = 8; // XX XX XX XX

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  bool get _isValid => _digits.length == _digitsNeeded;

  // The backend expects a plain `+993XXXXXXXX` string — the spaced
  // "XX XX XX XX" grouping in [_phoneController] is display-only.
  String get _apiPhone => '+993$_digits';

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    _termsTap.dispose();
    _authProvider.dispose();
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
    final digits =
        allDigits.substring(0, allDigits.length.clamp(0, _digitsNeeded));
    final formatted = _formatPhone(digits);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  Future<void> _sendCode() async {
    if (!_isValid || _authProvider.isLoading) return;
    HapticFeedback.lightImpact();
    final ok = await _authProvider.sendCode(_apiPhone);
    if (!mounted) return;
    if (!ok) {
      context.showAppSnackBar(
          _authProvider.errorMessage ?? AuthStrings.genericError,
          isError: true);
      return;
    }

    final loggedIn = await context.push<bool>(
      OtpVerifyScreen(
          phone: _apiPhone, simulateOtherDevice: _simulateOtherDevice),
    );
    if (loggedIn == true && mounted) {
      context.pop(true);
    }
  }

  Future<void> _openOtherMethods() async {
    final loggedIn = await context.push<bool>(const InternationalLoginScreen());
    if (loggedIn == true && mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authProvider,
      child: Consumer<AuthProvider>(
          builder: (context, auth, _) => _buildScaffold(context, auth)),
    );
  }

  Widget _buildScaffold(BuildContext context, AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).viewInsets.bottom -
                    MediaQuery.of(context).padding.vertical -
                    32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBackButton(),
                const SizedBox(height: 12),
                const GradientIconBadge(
                    icon: HugeIcons.strokeRoundedSmartPhone01),
                const SizedBox(height: 24),
                Text(
                  AuthStrings.phoneLoginTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  AuthStrings.phoneLoginSubtitle,
                  style: TextStyle(
                      color: AppColors.grey2, fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _phoneController,
                  focusNode: _focusNode,
                  label: AuthStrings.phoneNumberLabel,
                  hint: AuthStrings.phoneHint,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11)
                  ],
                  style: TextStyle(
                      color: AppColors.white, fontSize: 16, letterSpacing: 1),
                  onChanged: _onPhoneChanged,
                  prefix: Row(
                    children: [
                      const Text('🇹🇲', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('+993',
                          style: TextStyle(
                              color: AppColors.grey1,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 1,
                          height: 22,
                          color: AppColors.border),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                    label: AuthStrings.sendCodeButton,
                    loading: auth.isLoading,
                    onPressed: _isValid ? _sendCode : null),
                const SizedBox(height: 14),
                // Column above is left-aligned (crossAxisAlignment.start), so
                // without this the RichText shrink-wraps to its own text
                // width and sits at the left edge — textAlign.center only
                // centers text *within* the widget's box, which does nothing
                // once that box is already exactly as wide as the text.
                SizedBox(
                  width: double.infinity,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          color: AppColors.grey3,
                          fontFamily: 'GilroyRegular',
                          fontSize: 11.5),
                      children: [
                        TextSpan(text: AuthStrings.termsPrefix),
                        TextSpan(
                          text: AuthStrings.termsLink,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'GilroyRegular',
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline),
                          recognizer: _termsTap,
                        ),
                        TextSpan(text: AuthStrings.termsSuffix),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                OrDivider(label: AuthStrings.orDivider),
                const SizedBox(height: 16),
                AuthProviderButton(
                  icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLoginCircle02,
                      color: AppColors.white,
                      size: 20),
                  label: AuthStrings.otherMethodsLink,
                  onPressed: _openOtherMethods,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
