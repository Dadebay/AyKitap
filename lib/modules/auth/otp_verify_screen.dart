import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/device_fingerprint.dart';
import '../../core/localization/strings/auth_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_completion.dart';
import 'provider/auth_provider.dart';
import 'widgets/other_device_dialog.dart';
import 'widgets/otp_code_row.dart';

/// OTP tassyklamak — TZ section 2.1/2.3, plus the "bir hasap — bir telefon"
/// device-lock confirmation from 2.2 when a second device tries to log in.
class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final bool simulateOtherDevice;
  const OtpVerifyScreen(
      {super.key, required this.phone, this.simulateOtherDevice = false});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _length = 4;
  late final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());

  String? _error;
  final _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _authProvider.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    setState(() => _error = null);
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_code.length == _length) {
      _verify();
    }
  }

  Future<void> _verify() async {
    if (_authProvider.isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    // Already resolved and cached by the time we get here (warmed at app
    // start in main.dart) — this just reads the cache.
    final deviceId = await DeviceFingerprint.get();
    final result = await _authProvider.verifyLogin(
        phone: widget.phone, code: _code, deviceId: deviceId);
    if (!mounted) return;
    if (result == null) {
      setState(() =>
          _error = _authProvider.errorMessage ?? AuthStrings.genericError);
      return;
    }

    if (widget.simulateOtherDevice) {
      final confirmed = await showOtherDeviceDialog(context);
      // Bail out before touching AuthSession — a cancelled "other device"
      // confirmation must leave the previous session (if any) untouched,
      // same as if verifyLogin above had never been called.
      if (confirmed != true) return;
    }
    if (!mounted) return;

    await completeBackendLogin(context, result, phone: widget.phone);
    if (mounted) context.pop(true);
  }

  Future<void> _resend() async {
    if (_authProvider.isLoading) return;
    HapticFeedback.lightImpact();
    final ok = await _authProvider.sendCode(widget.phone);
    if (!mounted) return;
    if (!ok) {
      context.showAppSnackBar(
          _authProvider.errorMessage ?? AuthStrings.genericError,
          isError: true);
      return;
    }
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _error = null);
    _focusNodes[0].requestFocus();
    context.showAppSnackBar(AuthStrings.resendSnackbar);
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
                const GradientIconBadge(icon: HugeIcons.strokeRoundedMessage01),
                const SizedBox(height: 24),
                Text(AuthStrings.otpTitle,
                    style: TextStyle(
                        color: AppColors.white,
                        fontFamily: 'GilroyRegular',
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: AppColors.grey2,
                        fontFamily: 'GilroyRegular',
                        fontSize: 14.5,
                        height: 1.5),
                    children: [
                      TextSpan(text: AuthStrings.otpSentPrefix),
                      TextSpan(
                          text: widget.phone,
                          style: TextStyle(
                              color: AppColors.grey1,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                OtpCodeRow(
                    length: _length,
                    controllers: _controllers,
                    focusNodes: _focusNodes,
                    onChanged: _onDigitChanged),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    onTap: _resend,
                    child: Text(AuthStrings.resendAction,
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: AuthStrings.confirmButton,
                  loading: auth.isLoading,
                  onPressed: _code.length == _length ? _verify : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
