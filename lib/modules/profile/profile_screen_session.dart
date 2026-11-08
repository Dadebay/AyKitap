part of 'profile_screen.dart';

/// Session/auth-related behavior for [_ProfileScreenState]: reading the
/// logged-in identity from local + backend sources, and the navigation
/// flows that can change it (edit profile, login, settings/logout).
extension _ProfileScreenSession on _ProfileScreenState {
  // The bearer token in secure storage is the single source of truth for
  // "logged in" — re-read it instead of trusting whatever this widget's
  // in-memory state happened to be (it wouldn't survive an app restart).
  Future<void> _refreshSession() async {
    final loggedIn = await _refreshLocalSession();
    if (loggedIn) unawaited(_syncFromBackend());
  }

  /// Just the local half of [_refreshSession] — re-reads [AuthSession] into
  /// state without touching the backend. Returns whether the device is
  /// logged in, so [_refreshSession] can decide whether a backend sync is
  /// even worth attempting.
  ///
  /// Split out for [_openEditProfile]: right after a save, the backend half
  /// ([_syncFromBackend]) is only safe to run when that save is known to have
  /// actually reached the backend — see its call site.
  Future<bool> _refreshLocalSession() async {
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
    return loggedIn;
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
    // The bool here is [EditProfileScreen._save]'s `backendSynced`, not "did
    // anything change" — a local edit always happened by the time that
    // screen pops, so the name/avatar are re-read from local storage either
    // way. What it *does* gate is the backend half: re-fetching `/users/me`
    // right after a PATCH that's known to have failed would just read back
    // the pre-edit record and silently revert the edit that was just made
    // (see that screen's doc comment — this was the actual bug behind
    // "the name reverts after saving," seen more on a flakier connection).
    final backendSynced = await context.push<bool>(const EditProfileScreen());
    if (backendSynced == null || !mounted) return;
    await _refreshLocalSession();
    if (backendSynced) unawaited(_syncFromBackend());
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
