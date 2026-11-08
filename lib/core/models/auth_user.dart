/// The `data.user.subscription` object `/users/me` carries once the user
/// has ever bought a plan — set by `POST /users/buy-subscription/:id`
/// ([PaymentApiService.buySubscription]), which returns the same shape.
/// Null on the user itself (not an empty object) when no subscription has
/// ever been bought.
class AuthSubscription {
  /// Every field here has shown up null in the wild on subscriptions granted
  /// some other way (e.g. a streak reward) rather than
  /// [PaymentApiService.buySubscription] — none of them are trustworthy
  /// enough to parse as required. [expiredAt] null reads as "no known
  /// expiry", which [SubscriptionService.isActive]'s `expiredAt != null &&
  /// ...` already treats as inactive rather than a crash.
  final int? tariffId;
  final DateTime? activatedAt;
  final DateTime? expiredAt;

  const AuthSubscription(
      {required this.tariffId,
      required this.activatedAt,
      required this.expiredAt});

  factory AuthSubscription.fromJson(Map<String, dynamic> json) =>
      AuthSubscription(
        tariffId: json['tariff_id'] as int?,
        activatedAt: DateTime.tryParse(json['activated_at'] as String? ?? ''),
        expiredAt: DateTime.tryParse(json['expired_at'] as String? ?? ''),
      );
}

/// The `data.user` object returned by `/users/verify-login` (TZ 2.1/2.3).
/// A brand-new account comes back with [username] and [image] both null —
/// that's how the caller tells "just registered" apart from "logging back
/// in" without a separate signup endpoint.
class AuthUser {
  final int id;
  final String phone;
  final String? username;
  final String? image;
  final int balance;
  final AuthSubscription? subscription;

  const AuthUser({
    required this.id,
    required this.phone,
    this.username,
    this.image,
    required this.balance,
    this.subscription,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        phone: json['phone'] as String? ?? '',
        username: json['username'] as String?,
        image: json['image'] as String?,
        balance: json['balance'] as int? ?? 0,
        subscription: json['subscription'] != null
            ? AuthSubscription.fromJson(
                json['subscription'] as Map<String, dynamic>)
            : null,
      );
}
