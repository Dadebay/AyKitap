import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/device_fingerprint.dart';
import '../../core/localization/strings/auth_strings.dart';
import 'name_entry_screen.dart';

/// OTP tassyklamak — TZ section 2.1/2.3, plus the "bir hasap — bir telefon"
/// device-lock confirmation from 2.2 when a second device tries to log in.
class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final bool simulateOtherDevice;
  const OtpVerifyScreen({super.key, required this.phone, this.simulateOtherDevice = false});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _length = 4;
  late final List<TextEditingController> _controllers = List.generate(_length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 30;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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
    if (_verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    // Already resolved and cached by the time we get here (warmed at app
    // start in main.dart) — this just reads the cache.
    // TODO(backend): once the OTP-verify endpoint accepts a device
    // fingerprint field, send `deviceId` in that request body so the
    // server can enforce "bir hasap — bir enjam" (TZ 2.2) itself instead
    // of the client-side `simulateOtherDevice` mock below.
    final deviceId = await DeviceFingerprint.get();
    await Future.delayed(const Duration(milliseconds: 800)); // mock network
    if (!mounted) return;
    setState(() => _verifying = false);

    // Any 4-digit code is accepted in this mock.
    if (widget.simulateOtherDevice) {
      final confirmed = await _showOtherDeviceDialog();
      if (confirmed != true) return;
    }

    // A real backend would return this in the OTP-verify response. Its
    // presence in secure storage is what the rest of the app treats as
    // "logged in".
    await AuthSession.saveToken('mock-bearer-${DateTime.now().millisecondsSinceEpoch}', phone: widget.phone);
    debugPrint('device fingerprint ready to send once the API accepts it: $deviceId');

    // First-time account (no name on file yet) — the real backend would
    // tell us this is a signup rather than a login; here we just key off
    // whether a name was ever saved. Mandatory: no back arrow, no skip.
    if (await AuthSession.getName() == null) {
      if (!mounted) return;
      final name = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const NameEntryScreen()));
      if (name != null) await AuthSession.saveName(name);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<bool?> _showOtherDeviceDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedSecurityLock, color: AppColors.primary, size: 26)),
        ),
        title: Text(
          AuthStrings.otherDeviceTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          AuthStrings.otherDeviceBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey2, fontSize: 13.5, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AuthStrings.otherDeviceConfirm, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AuthStrings.cancel, style: TextStyle(color: AppColors.grey2, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    HapticFeedback.lightImpact();
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _error = null);
    _startTimer();
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AuthStrings.resendSnackbar)));
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
                IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF77E68), Color(0xFFB44BE8)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: HugeIcon(icon: HugeIcons.strokeRoundedMessage01, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 24),
                Text(AuthStrings.otpTitle, style: TextStyle(color: AppColors.white, fontFamily: 'GilroyRegular', fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppColors.grey2, fontFamily: 'GilroyRegular', fontSize: 14.5, height: 1.5),
                    children: [
                      TextSpan(text: AuthStrings.otpSentPrefix),
                      TextSpan(text: widget.phone, style: TextStyle(color: AppColors.grey1, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_length, (i) => _buildDigitBox(i)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 28),
                Center(
                  child: _secondsLeft > 0
                      ? Text(AuthStrings.resendCountdown(_secondsLeft.toString().padLeft(2, '0')), style: TextStyle(color: AppColors.grey3, fontSize: 13))
                      : GestureDetector(
                          onTap: _resend,
                          child: Text(AuthStrings.resendAction, style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _code.length == _length ? AppColors.primary : AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _code.length == _length ? _verify : null,
                    child: _verifying
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(
                            AuthStrings.confirmButton,
                            style: TextStyle(color: _code.length == _length ? Colors.white : AppColors.grey3, fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildDigitBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 68,
      height: 64,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: filled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: filled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (v) => _onDigitChanged(index, v),
        onTap: () => setState(() {}),
      ),
    );
  }
}
