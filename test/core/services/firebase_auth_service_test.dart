import 'package:aykitap/core/services/firebase_auth_client.dart';
import 'package:aykitap/core/services/firebase_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the service asked the SDK to do, without a platform
/// channel — same shape as `_FakeOneSignalClient` in onesignal_service_test.
class _FakeFirebaseAuthClient implements FirebaseAuthClient {
  _FakeFirebaseAuthClient({this.throwOn});

  /// If set, the matching method throws this instead of succeeding.
  final FirebaseAuthClientException? throwOn;

  final List<String> emailSignIns = <String>[];
  final List<String> emailRegistrations = <String>[];
  int googleSignIns = 0;
  int appleSignIns = 0;
  int signOuts = 0;

  static const _result = FirebaseSignInResult(
    idToken: 'fake-id-token',
    displayName: 'Aygul',
    email: 'aygul@example.com',
  );

  @override
  Future<FirebaseSignInResult> signInWithEmail(
      String email, String password) async {
    if (throwOn != null) throw throwOn!;
    emailSignIns.add(email);
    return _result;
  }

  @override
  Future<FirebaseSignInResult> registerWithEmail(
      String email, String password) async {
    if (throwOn != null) throw throwOn!;
    emailRegistrations.add(email);
    return _result;
  }

  @override
  Future<FirebaseSignInResult> signInWithGoogle() async {
    if (throwOn != null) throw throwOn!;
    googleSignIns++;
    return _result;
  }

  @override
  Future<FirebaseSignInResult> signInWithApple() async {
    if (throwOn != null) throw throwOn!;
    appleSignIns++;
    return _result;
  }

  @override
  Future<void> signOut() async {
    if (throwOn != null) throw throwOn!;
    signOuts++;
  }
}

void main() {
  group('FirebaseAuthService', () {
    test('signInWithEmail trims the email and delegates to the client',
        () async {
      final client = _FakeFirebaseAuthClient();
      final service = FirebaseAuthService.forTest(client);

      final result =
          await service.signInWithEmail('  aygul@example.com  ', 'secret1');

      expect(result.idToken, 'fake-id-token');
      expect(client.emailSignIns, ['aygul@example.com']);
    });

    test('registerWithEmail delegates to the client', () async {
      final client = _FakeFirebaseAuthClient();
      final service = FirebaseAuthService.forTest(client);

      await service.registerWithEmail('new@example.com', 'secret1');

      expect(client.emailRegistrations, ['new@example.com']);
    });

    test('signInWithGoogle delegates to the client', () async {
      final client = _FakeFirebaseAuthClient();
      final service = FirebaseAuthService.forTest(client);

      await service.signInWithGoogle();

      expect(client.googleSignIns, 1);
    });

    test('signInWithApple delegates to the client', () async {
      final client = _FakeFirebaseAuthClient();
      final service = FirebaseAuthService.forTest(client);

      await service.signInWithApple();

      expect(client.appleSignIns, 1);
    });

    test('failures propagate with their failure code intact', () async {
      final client = _FakeFirebaseAuthClient(
        throwOn: const FirebaseAuthClientException(
            FirebaseAuthFailure.wrongPassword, 'bad password'),
      );
      final service = FirebaseAuthService.forTest(client);

      await expectLater(
        () => service.signInWithEmail('aygul@example.com', 'wrong'),
        throwsA(isA<FirebaseAuthClientException>().having(
            (e) => e.failure, 'failure', FirebaseAuthFailure.wrongPassword)),
      );
    });

    test('signOut never throws, even if the client fails', () async {
      final client = _FakeFirebaseAuthClient(
        throwOn: const FirebaseAuthClientException(FirebaseAuthFailure.unknown),
      );
      final service = FirebaseAuthService.forTest(client);

      await service.signOut(); // must not throw
    });
  });
}
