import 'bank.dart';

/// One row from `GET /payments/my` — a bank-card top-up order the
/// signed-in user has made, newest first. Distinct from [BalanceLog]
/// (`/users/balance-logs`, book purchases + generic balance events) —
/// this is specifically the card-payment orders themselves.
///
/// The backend's `bank` object here also carries `login`/`password` (its
/// own merchant credentials for that bank's gateway) — [Bank.fromJson]
/// only ever reads `id`/`name`, so those never end up anywhere in the app,
/// but the endpoint sending them to the client at all is worth flagging to
/// the backend.
class PaymentOrder {
  final int id;
  final int amount;
  final Bank bank;
  final DateTime createdAt;

  const PaymentOrder(
      {required this.id,
      required this.amount,
      required this.bank,
      required this.createdAt});

  factory PaymentOrder.fromJson(Map<String, dynamic> json) => PaymentOrder(
        id: json['id'] as int,
        amount: json['amount'] as int? ?? 0,
        bank: Bank.fromJson(json['bank'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
