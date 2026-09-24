/// The name a provider already told us, so the app never asks for it again.
///
/// App Store guideline 4 (review 18.09.2026, submission
/// e0e19fe2-b984-457a-a9da-bd9b754e4c5e): *"users are required to provide
/// their name and/or email address after using Sign in with Apple even
/// though that information is already provided by the Authentication
/// Services framework."* The Sign in with Apple, Google and email doors all
/// hand back something usable, so [NameEntryScreen] must not appear after
/// any of them.
///
/// Order:
/// 1. [displayName] — what Apple returns on the first authorization (given +
///    family name) and what Google always returns. Firebase keeps it on the
///    account afterwards, so a returning Apple user still has one even
///    though Apple itself only discloses the name once.
/// 2. The local part of [email] — `dadebay@gmail.com` becomes `dadebay`.
///
/// Apple's private-relay addresses are deliberately excluded: their local
/// part is a random string (`jz59fjq85q@privaterelay.appleid.com`), which is
/// worse than no name at all. Returning null leaves the caller to ask, which
/// is still correct for a phone/OTP signup — that door supplies no name, so
/// it is not what the guideline is about.
String? suggestedDisplayName({String? displayName, String? email}) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) return name;

  final address = email?.trim();
  if (address == null || address.isEmpty) return null;
  final at = address.indexOf('@');
  if (at <= 0) return null;
  if (address.toLowerCase().endsWith('@privaterelay.appleid.com')) return null;
  final local = address.substring(0, at).trim();
  return local.isEmpty ? null : local;
}
