import 'package:aykitap/core/services/premium_access_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumAccessService.computeIsPremium', () {
    test('true when only the wallet subscription is active', () {
      expect(
        PremiumAccessService.computeIsPremium(
            walletActive: true, storeActive: false),
        isTrue,
      );
    });

    test('true when only the store entitlement is active', () {
      expect(
        PremiumAccessService.computeIsPremium(
            walletActive: false, storeActive: true),
        isTrue,
      );
    });

    test('true when both are active', () {
      expect(
        PremiumAccessService.computeIsPremium(
            walletActive: true, storeActive: true),
        isTrue,
      );
    });

    test('false when neither is active', () {
      expect(
        PremiumAccessService.computeIsPremium(
            walletActive: false, storeActive: false),
        isFalse,
      );
    });
  });

  group('PremiumAccessService.computeExpiresAt', () {
    final earlier = DateTime.utc(2026, 1, 1);
    final later = DateTime.utc(2026, 6, 1);

    test('returns the wallet expiry when the store one is null', () {
      expect(
        PremiumAccessService.computeExpiresAt(
            walletExpiresAt: earlier, storeExpiresAt: null),
        earlier,
      );
    });

    test('returns the store expiry when the wallet one is null', () {
      expect(
        PremiumAccessService.computeExpiresAt(
            walletExpiresAt: null, storeExpiresAt: later),
        later,
      );
    });

    test('returns null when neither is active', () {
      expect(
        PremiumAccessService.computeExpiresAt(
            walletExpiresAt: null, storeExpiresAt: null),
        isNull,
      );
    });

    test(
        'returns the later of the two when both are active — a reader '
        'should not lose access on whichever expires first', () {
      expect(
        PremiumAccessService.computeExpiresAt(
            walletExpiresAt: earlier, storeExpiresAt: later),
        later,
      );
      expect(
        PremiumAccessService.computeExpiresAt(
            walletExpiresAt: later, storeExpiresAt: earlier),
        later,
      );
    });
  });
}
