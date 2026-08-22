part of 'profile_screen.dart';

/// Session/auth-related behavior for [_ProfileScreenState]: reading the
/// logged-in identity from local + backend sources, and the navigation
/// flows that can change it (edit profile, login, settings/logout).
extension _ProfileScreenSession on _ProfileScreenState {
  // The bearer token in secure storage is the single source of truth for
  // "logged in" — re-read it instead of trusting whatever this widget's
  // in-memory state happened to be (it wouldn't survive an app restart).
  Future<void> _refreshSession() async {
    final loggedIn = await AuthSession.isLoggedIn();
    final phone = await AuthSession.getPhone();
    final name = await AuthSession.getName();
    final avatar = await AuthSession.getAvatar();
    final avatarImage = await AuthSession.getAvatarImage();
    if (mounted) {
      _setState(() {
        _isLoggedIn = loggedIn;
        _phone = phone ?? '';
        _name = (name != null && name.isNotEmpty)
            ? name
            : ProfileStrings.defaultReaderName;
        _avatarIndex = avatar;
        _avatarImage = avatarImage;
      });
    }
    if (loggedIn) unawaited(_syncFromBackend());
  }

  // Best-effort only: the locally cached values (read above) are already
  // what the rest of the app renders off of, so a `/users/me` failure here
  // (offline, expired token, ...) is silently ignored rather than surfaced —
  // this just keeps name/phone/avatar/balance fresh when the backend has a
  // newer copy (e.g. edited from another device).
  //
  // Routed through [AccountService] rather than calling [AuthApiService]
  // directly so the balance this screen shows is the same cached record the
  // rest of the app spends from, refreshed by one request instead of two.
  Future<void> _syncFromBackend() async {
    await AccountService.instance.refresh();
    final user = AccountService.instance.user;
    if (user == null) return; // Offline — keep the locally cached values.
    final username = user.username;
    if (username != null && username.isNotEmpty && username != _name) {
      await AuthSession.saveName(username);
    }
    if (!mounted) return;
    _setState(() {
      if (username != null && username.isNotEmpty) _name = username;
      if (user.phone.isNotEmpty) _phone = user.phone;
      _backendAvatarUrl = (user.image != null && user.image!.isNotEmpty)
          ? ApiConfig.resolveImageUrl(user.image!)
          : null;
    });
  }

  // TZ 8.1: phone shown half-hidden as "+993 XX ***XX". Works off the digits
  // so it's robust to whatever spacing the stored value happens to have.
  String get _maskedPhone {
    final digits = _phone.replaceAll(RegExp(r'\D'), '');
    // Strip the 993 country code if present, leaving the 8-digit local number.
    final local = digits.startsWith('993') ? digits.substring(3) : digits;
    if (local.length < 4) return _phone;
    final first = local.substring(0, 2);
    final last = local.substring(local.length - 2);
    return '+993 $first ***$last';
  }

  Future<void> _openEditProfile() async {
    final result = await context.push<bool>(const EditProfileScreen());
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _startLogin() async {
    final result = await context.push<bool>(const PhoneLoginScreen());
    if (result == true && mounted) await _refreshSession();
  }

  Future<void> _openSettings() async {
    final result =
        await context.push<String>(SettingsScreen(isLoggedIn: _isLoggedIn));
    if (result == 'logout' && mounted) {
      _setState(() => _isLoggedIn = false);
    }
  }
}
