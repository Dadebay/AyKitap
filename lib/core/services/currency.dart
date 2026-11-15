import 'auth_session.dart';

/// The app's money is written as "TMT" in every translation. Accounts that
/// signed in with Google/Apple/email (see [AuthSession.isInternational]) see
/// dollars instead, so rather than touching ~90 strings they all pass through
/// [localize], which [t] applies to every translated string.
abstract final class Currency {
  static final _amountThenCode = RegExp(r'(\d[\d.,]*)\s*TMT');

  /// "50 TMT" -> "$50", a bare "TMT" (e.g. "Amount (TMT)") -> "$".
  static String localize(String text) {
    if (!AuthSession.isInternational || !text.contains('TMT')) return text;
    return text
        .replaceAllMapped(_amountThenCode, (m) => '\$${m[1]}')
        .replaceAll('TMT', '\$');
  }

  /// The code/symbol for places that build a price by hand.
  static String get symbol => AuthSession.isInternational ? '\$' : 'TMT';
}
