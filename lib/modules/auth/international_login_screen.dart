import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/constants/app_radius.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/strings/auth_strings.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/or_divider.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_completion.dart';
import 'widgets/auth_provider_button.dart';

/// The "another method" door alongside the +993 phone/OTP flow
/// ([PhoneLoginScreen]) — email/password, Google, and (iOS only, per App
/// Store guideline 4.8: any third-party sign-in on iOS requires Sign in with
/// Apple alongside it) Apple. Every provider ends the same way: a Firebase ID
/// token traded for an Aýkitap session via [AuthApiService.firebaseLogin],
/// then the same [completeBackendLogin] pipeline [OtpVerifyScreen] uses.
class InternationalLoginScreen extends StatefulWidget {
  const InternationalLoginScreen({super.key});

  @override
  State<InternationalLoginScreen> createState() =>
      _InternationalLoginScreenState();
}

enum _Busy { none, email, google, apple }

class _InternationalLoginScreenState extends State<InternationalLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  _Busy _busy = _Busy.none;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _emailValid => _emailController.text.contains('@');
  bool get _passwordValid => _passwordController.text.length >= 6;

  Future<void> _finishLogin(String idToken, String loginMethod) async {
    final result = await AuthApiService.firebaseLogin(idToken: idToken);
    if (!mounted) return;
    await completeBackendLogin(context, result, loginMethod: loginMethod);
    if (mounted) context.pop(true);
  }

  Future<void> _submitEmail() async {
    if (_busy != _Busy.none || !_emailValid || !_passwordValid) return;
    setState(() {
      _busy = _Busy.email;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final signIn = _isRegisterMode
          ? FirebaseAuthService.instance.registerWithEmail
          : FirebaseAuthService.instance.signInWithEmail;
      final result = await signIn(email, password);
      await _finishLogin(result.idToken, 'email');
    } on FirebaseAuthClientException catch (e) {
      _handleFirebaseError(e);
    } on ApiException catch (e) {
      _handleApiError(e);
    }
  }

  Future<void> _submitGoogle() async {
    if (_busy != _Busy.none) return;
    setState(() {
      _busy = _Busy.google;
      _error = null;
    });
    try {
      final result = await FirebaseAuthService.instance.signInWithGoogle();
      await _finishLogin(result.idToken, 'google');
    } on FirebaseAuthClientException catch (e) {
      _handleFirebaseError(e);
    } on ApiException catch (e) {
      _handleApiError(e);
    }
  }

  Future<void> _submitApple() async {
    if (_busy != _Busy.none) return;
    setState(() {
      _busy = _Busy.apple;
      _error = null;
    });
    try {
      final result = await FirebaseAuthService.instance.signInWithApple();
      await _finishLogin(result.idToken, 'apple');
    } on FirebaseAuthClientException catch (e) {
      _handleFirebaseError(e);
    } on ApiException catch (e) {
      _handleApiError(e);
    }
  }

  // The banner only ever shows a short, localized, user-facing message — the
  // actual failure (Firebase error code, HTTP status) is easy to lose track
  // of once that's all a tester sees on screen. Printed here so it shows up
  // in `flutter run`/logcat instead, without exposing it in the UI itself.
  void _handleFirebaseError(FirebaseAuthClientException e) {
    debugPrint('International login failed | failure=${e.failure} '
        '| message=${e.message}');
    if (!mounted) return;
    if (e.failure == FirebaseAuthFailure.cancelled) {
      setState(() => _busy = _Busy.none);
      return;
    }
    setState(() {
      _busy = _Busy.none;
      _error = _messageFor(e.failure);
    });
  }

  void _handleApiError(ApiException e) {
    debugPrint('International login backend exchange failed | '
        'status=${e.statusCode} | message=${e.message}');
    if (!mounted) return;
    setState(() {
      _busy = _Busy.none;
      _error = e.message;
    });
  }

  String _messageFor(FirebaseAuthFailure failure) {
    switch (failure) {
      case FirebaseAuthFailure.invalidEmail:
        return AuthStrings.firebaseErrorInvalidEmail;
      case FirebaseAuthFailure.wrongPassword:
        return AuthStrings.firebaseErrorWrongPassword;
      case FirebaseAuthFailure.userNotFound:
        return AuthStrings.firebaseErrorUserNotFound;
      case FirebaseAuthFailure.emailAlreadyInUse:
        return AuthStrings.firebaseErrorEmailInUse;
      case FirebaseAuthFailure.weakPassword:
        return AuthStrings.firebaseErrorWeakPassword;
      case FirebaseAuthFailure.networkError:
        return AuthStrings.firebaseErrorNetwork;
      case FirebaseAuthFailure.cancelled:
      case FirebaseAuthFailure.unknown:
        return AuthStrings.genericError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              const SizedBox(height: 12),
              const GradientIconBadge(icon: HugeIcons.strokeRoundedUserAccount),
              const SizedBox(height: 24),
              Text(AuthStrings.internationalLoginTitle,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(AuthStrings.internationalLoginSubtitle,
                  style: TextStyle(
                      color: AppColors.grey2, fontSize: 14.5, height: 1.5)),
              const SizedBox(height: 32),
              AuthProviderButton.google(
                label: AuthStrings.continueWithGoogle,
                loading: _busy == _Busy.google,
                onPressed: _busy == _Busy.none ? _submitGoogle : null,
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                AuthProviderButton.apple(
                  label: AuthStrings.continueWithApple,
                  loading: _busy == _Busy.apple,
                  onPressed: _busy == _Busy.none ? _submitApple : null,
                ),
              ],
              const SizedBox(height: 24),
              OrDivider(label: AuthStrings.orDivider),
              const SizedBox(height: 24),
              AppTextField(
                controller: _emailController,
                label: AuthStrings.emailLabel,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: AppColors.white, fontSize: 16),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _passwordController,
                label: AuthStrings.passwordLabel,
                obscureText: _obscurePassword,
                style: TextStyle(color: AppColors.white, fontSize: 16),
                onChanged: (_) => setState(() {}),
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: HugeIcon(
                      icon: _obscurePassword
                          ? HugeIcons.strokeRoundedView
                          : HugeIcons.strokeRoundedViewOffSlash,
                      color: AppColors.grey3,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isRegisterMode
                    ? AuthStrings.emailRegisterButton
                    : AuthStrings.emailSignInButton,
                loading: _busy == _Busy.email,
                onPressed: _emailValid && _passwordValid && _busy == _Busy.none
                    ? _submitEmail
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _isRegisterMode = !_isRegisterMode),
                  child: RichText(
                    text: TextSpan(
                      // RichText doesn't inherit the app's default font from
                      // the surrounding theme the way Text does — every
                      // TextSpan here needs it spelled out explicitly, same
                      // as the terms RichText on PhoneLoginScreen.
                      style: TextStyle(
                          color: AppColors.grey2,
                          fontFamily: 'GilroyRegular',
                          fontSize: 13),
                      children: [
                        TextSpan(
                            text: _isRegisterMode
                                ? AuthStrings.emailTogglePrefixHaveAccount
                                : AuthStrings.emailTogglePrefixNoAccount),
                        TextSpan(
                          text: _isRegisterMode
                              ? AuthStrings.emailToggleToSignIn
                              : AuthStrings.emailToggleToRegister,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'GilroyRegular',
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet red-tinted card for a form-level error — one small step up from
/// bare red text, without turning a wrong password into a modal interruption.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              color: Colors.redAccent,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}
