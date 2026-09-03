import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/theme/app_colors.dart';

/// Google's own four-color "G" mark (their brand guidelines call for this
/// exact glyph on a "Continue/Sign in with Google" button, not a stroke-icon
/// stand-in) — inlined rather than a bundled asset since it's the one glyph
/// this app needs from a brand that ships no Flutter/HugeIcons package.
const _googleGLogo = '''
<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.874 2.6836-6.615z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.0359-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.9641 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1023-1.17.2822-1.71V4.9582H.9573C.3477 6.1732 0 7.5477 0 9c0 1.4523.3477 2.8268.9573 4.0418L3.9641 10.71z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5814-2.5814C13.4632.8918 11.4259 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.9641 7.29C4.6718 5.1627 6.656 3.5795 9 3.5795z"/>
</svg>
''';

/// Apple's own bitten-apple mark — like [_googleGLogo], Apple's Sign in with
/// Apple guidelines call for this exact glyph rather than a stroke-icon
/// stand-in, and HugeIcons ships no Apple brand mark to draw it from.
const _appleLogo = '''
<svg width="18" height="18" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="#FFFFFF" d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.087 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zm3.632-3.322c.842-1.014 1.409-2.427 1.257-3.831-1.211.052-2.677.805-3.549 1.818-.78.896-1.462 2.336-1.28 3.71 1.345.104 2.729-.688 3.572-1.697z"/>
</svg>
''';

/// A full-width, bordered secondary button for a third-party sign-in option
/// (Google, Apple) — same 56px height as [PrimaryButton] so the two stack
/// without a visual size jump, but card-colored/bordered rather than filled,
/// since neither is *the* primary action on [InternationalLoginScreen].
class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  factory AuthProviderButton.google({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return AuthProviderButton(
      key: key,
      icon: SvgPicture.string(_googleGLogo, width: 20, height: 20),
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }

  factory AuthProviderButton.apple({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return AuthProviderButton(
      key: key,
      icon: SvgPicture.string(_appleLogo, width: 20, height: 20),
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.grey2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label,
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
