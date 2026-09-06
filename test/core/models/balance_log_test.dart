import 'package:aykitap/core/models/balance_log.dart';
import 'package:aykitap/core/services/balance_log_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceLog _log(String event, {int amount = 10}) => BalanceLog(
      id: 1,
      createdAt: DateTime(2026, 9, 6),
      amount: amount,
      event: event,
    );

BalanceLog _transferLog({
  required int id,
  required String event,
  required DateTime createdAt,
  int amount = 7,
}) =>
    BalanceLog(
      id: id,
      createdAt: createdAt,
      amount: amount,
      event: event,
    );

void main() {
  group('BalanceLog direction', () {
    test('a sent gift is a debit even when the stored amount is positive', () {
      final log = _log('SEND_TO_FRIEND');

      expect(log.isDebit, isTrue);
      expect(log.isCredit, isFalse);
    });

    test('an incoming gift remains a credit', () {
      final log = _log('COME_FROM_FRIEND');

      expect(log.isDebit, isFalse);
      expect(log.isCredit, isTrue);
    });
  });

  group('mirrored gift log filtering', () {
    test('removes the backend-created incoming mirror from the sender', () {
      final sentAt = DateTime(2026, 9, 6, 21, 25);
      final logs = [
        _transferLog(
          id: 42,
          event: 'SEND_TO_FRIEND',
          createdAt: sentAt,
        ),
        _transferLog(
          id: 43,
          event: 'COME_FROM_FRIEND',
          createdAt: sentAt.add(const Duration(milliseconds: 100)),
        ),
      ];

      final filtered = removeMirroredIncomingGiftLogs(logs);

      expect(filtered.map((log) => log.event), ['SEND_TO_FRIEND']);
    });

    test('keeps a genuine incoming gift without a matching sent row', () {
      final incoming = _transferLog(
        id: 51,
        event: 'COME_FROM_FRIEND',
        createdAt: DateTime(2026, 9, 6, 21, 25),
      );

      expect(removeMirroredIncomingGiftLogs([incoming]), [incoming]);
    });
  });
}
