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

  const AuthUser({
    required this.id,
    required this.phone,
    this.username,
    this.image,
    required this.balance,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        phone: json['phone'] as String? ?? '',
        username: json['username'] as String?,
        image: json['image'] as String?,
        balance: json['balance'] as int? ?? 0,
      );
}
