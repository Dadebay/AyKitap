/// One row from `GET /payments/banks` — a bank card payment option shown
/// in the bank-selection sheet before checkout.
class Bank {
  final int id;
  final String name;
  const Bank({required this.id, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );

  /// A bundled logo for the handful of banks we have branding assets for
  /// (`assets/images/banks/`) — matched by name substring since the
  /// backend's `name` text doesn't line up with any stable code. Anything
  /// else (a bank added later, a name that doesn't match) falls back to a
  /// generic bank icon rather than showing the wrong logo.
  String? get logoAsset {
    final n = name.toLowerCase();
    if (n.contains('halk')) return 'assets/images/banks/halk.webp';
    if (n.contains('rysgal')) return 'assets/images/banks/rysgal.webp';
    if (n.contains('senagat')) return 'assets/images/banks/senagat.webp';
    return null;
  }
}
