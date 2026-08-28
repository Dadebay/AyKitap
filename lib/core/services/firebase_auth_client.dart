import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// One successful Firebase sign-in, reduced to what the backend exchange
/// ([AuthApiService.firebaseLogin]) and the shared post-login pipeline need —
/// never the raw SDK `User`, so callers can't reach for a Firebase-only field
/// the backend doesn't know about.
class FirebaseSignInResult {
  const FirebaseSignInResult({
    required this.idToken,
    this.displayName,
    this.email,
  });

  final String idToken;
  final String? displayName;
  final String? email;
}

enum FirebaseAuthFailure {
  invalidEmail,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  cancelled,
  unknown,
}

/// Thrown by every [FirebaseAuthClient] method for anything other than
/// success. [FirebaseAuthFailure.cancelled] is not an error the UI should
/// show a message for — the user closed the Google/Apple sheet themselves.
class FirebaseAuthClientException implements Exception {
  const FirebaseAuthClientException(this.failure, [this.message]);

  final FirebaseAuthFailure failure;
  final String? message;

  @override
  String toString() => 'FirebaseAuthClientException($failure, $message)';
}

/// Seam over `firebase_auth`/`google_sign_in`/`sign_in_with_apple`'s SDK
/// calls — same reasoning as [OneSignalClient]: the real SDKs reach for a
/// platform channel, which throws under `flutter test`, so routing through
/// an interface is what makes [FirebaseAuthService] (error-mapping, which
/// provider to call) testable with a fake.
abstract class FirebaseAuthClient {
  Future<FirebaseSignInResult> signInWithEmail(String email, String password);
  Future<FirebaseSignInResult> registerWithEmail(String email, String password);
  Future<FirebaseSignInResult> signInWithGoogle();
  Future<FirebaseSignInResult> signInWithApple();
  Future<void> signOut();
}

/// The real SDKs. Every method here is a straight pass-through plus error
/// mapping — anything with a decision in it belongs in [FirebaseAuthService].
class LiveFirebaseAuthClient implements FirebaseAuthClient {
  LiveFirebaseAuthClient({String? googleServerClientId})
      : _googleServerClientId = googleServerClientId;

  /// The Google Cloud **Web** OAuth client id (not the Android/iOS one) —
  /// Android needs this passed as `serverClientId` for the resulting ID
  /// token's audience to be one Firebase (and this app's backend, which
  /// re-verifies it) will accept. iOS resolves its own client id from
  /// `GoogleService-Info.plist` and ignores this if unset.
  final String? _googleServerClientId;
  bool _googleInitialized = false;

  fb.FirebaseAuth get _auth => fb.FirebaseAuth.instance;

  @override
  Future<FirebaseSignInResult> signInWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return _resultFor(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<FirebaseSignInResult> registerWithEmail(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return _resultFor(credential.user);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<FirebaseSignInResult> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance
            .initialize(serverClientId: _googleServerClientId);
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const FirebaseAuthClientException(
            FirebaseAuthFailure.unknown, 'Google returned no ID token');
      }
      final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      return _resultFor(userCredential.user,
          fallbackDisplayName: account.displayName,
          fallbackEmail: account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const FirebaseAuthClientException(FirebaseAuthFailure.cancelled);
      }
      throw FirebaseAuthClientException(
          FirebaseAuthFailure.unknown, e.description);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<FirebaseSignInResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      // Apple only hands back the name/email on the *first* authorization —
      // every later sign-in has null here, which is why _resultFor prefers
      // the Firebase user's own copy (saved from that first time) first.
      final fullName = [appleCredential.givenName, appleCredential.familyName]
          .whereType<String>()
          .join(' ')
          .trim();
      return _resultFor(
        userCredential.user,
        fallbackDisplayName: fullName.isEmpty ? null : fullName,
        fallbackEmail: appleCredential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const FirebaseAuthClientException(FirebaseAuthFailure.cancelled);
      }
      throw FirebaseAuthClientException(FirebaseAuthFailure.unknown, e.message);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      // Throws if Google was never initialized/signed in this session —
      // harmless, and this method must stay best-effort either way.
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<FirebaseSignInResult> _resultFor(
    fb.User? user, {
    String? fallbackDisplayName,
    String? fallbackEmail,
  }) async {
    if (user == null) {
      throw const FirebaseAuthClientException(
          FirebaseAuthFailure.unknown, 'No Firebase user after sign-in');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw const FirebaseAuthClientException(
          FirebaseAuthFailure.unknown, 'No ID token');
    }
    return FirebaseSignInResult(
      idToken: idToken,
      displayName: user.displayName ?? fallbackDisplayName,
      email: user.email ?? fallbackEmail,
    );
  }

  static FirebaseAuthClientException _mapFirebaseException(
      fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.invalidEmail, e.message);
      case 'wrong-password':
      case 'invalid-credential':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.wrongPassword, e.message);
      case 'user-not-found':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.userNotFound, e.message);
      case 'email-already-in-use':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.emailAlreadyInUse, e.message);
      case 'weak-password':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.weakPassword, e.message);
      case 'network-request-failed':
        return FirebaseAuthClientException(
            FirebaseAuthFailure.networkError, e.message);
      default:
        return FirebaseAuthClientException(
            FirebaseAuthFailure.unknown, e.message);
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
