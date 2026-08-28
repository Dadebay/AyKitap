import 'package:flutter/foundation.dart';

import 'firebase_auth_client.dart';

export 'firebase_auth_client.dart'
    show FirebaseAuthFailure, FirebaseAuthClientException, FirebaseSignInResult;

/// Firebase-side half of international login (email/password, Google,
/// Apple) — [AuthApiService.firebaseLogin] is the other half, trading the ID
/// token this produces for an Aýkitap session. The +993 phone/OTP path in
/// [AuthApiService]/[AuthProvider] is untouched and doesn't go through here.
///
/// Unlike [OneSignalService]/[RevenueCatService] this has no boot-time
/// `init()` to queue behind — `Firebase.initializeApp()` already runs (and is
/// awaited) in `AnalyticsService.init()` before any screen that could call
/// this exists, so every method here can assume Firebase is up. If it isn't
/// (analytics disabled on an unsupported target), the SDK calls below throw
/// and the caller's own try/catch shows a generic error — same "never crash,
/// degrade the feature" rule as everywhere else this app talks to Firebase.
class FirebaseAuthService {
  FirebaseAuthService._({FirebaseAuthClient? client})
      : _client = client ??
            LiveFirebaseAuthClient(
              googleServerClientId:
                  _googleServerClientId.isEmpty ? null : _googleServerClientId,
            );

  static final instance = FirebaseAuthService._();

  /// Test seam — a service wired to a fake client, with no global state
  /// shared with [instance].
  @visibleForTesting
  factory FirebaseAuthService.forTest(FirebaseAuthClient client) =>
      FirebaseAuthService._(client: client);

  /// The Google Cloud **Web** OAuth client id from the Firebase console
  /// (Authentication → Sign-in method → Google → Web SDK configuration) —
  /// required on Android for the ID token's audience to be one Firebase (and
  /// this app's backend) accepts. Empty until the dashboard owner sets
  /// `--dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=<id>.apps.googleusercontent.com`;
  /// Google sign-in will fail clearly rather than silently until then.
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SIGN_IN_SERVER_CLIENT_ID');

  final FirebaseAuthClient _client;

  Future<FirebaseSignInResult> signInWithEmail(String email, String password) =>
      _client.signInWithEmail(email.trim(), password);

  Future<FirebaseSignInResult> registerWithEmail(
          String email, String password) =>
      _client.registerWithEmail(email.trim(), password);

  Future<FirebaseSignInResult> signInWithGoogle() => _client.signInWithGoogle();

  Future<FirebaseSignInResult> signInWithApple() => _client.signInWithApple();

  /// Best-effort, like every other logout side effect in this app — a
  /// Firebase outage must never keep the local session from clearing.
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (error) {
      debugPrint('FirebaseAuthService signOut failed | $error');
    }
  }
}
