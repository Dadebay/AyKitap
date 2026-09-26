/// Where a "TMCELL arkaly töleg" actually sends the money.
///
/// TMCELL's own balance transfer is an SMS from the reader's line to a short
/// code, whose body names the receiving number and the amount. The app does
/// not move the money itself — it composes that SMS and hands it to the
/// messaging app, where the reader sends it. The balance in Aýkitap is then
/// credited server-side once the transfer lands on one of our lines, exactly
/// as the bank-card path credits it once the bank confirms.
///
/// The receiving number is no longer here: it comes from the admin panel
/// through [TmcellNumbersApiService], which is also the list the backend
/// matches incoming transfers against. [fallbackReceiverPhone] is what is
/// left of the old build-time value — see its doc.
class TmcellPaymentConfig {
  TmcellPaymentConfig._();

  /// TMCELL's balance-transfer short code. The SMS goes here; the body says
  /// who it is for.
  static const String smsShortCode = '0804';

  /// A last-resort receiving number for a build that cannot reach the API.
  ///
  /// Optional, and normally empty: the live list is the one the backend
  /// credits from, so a hardcoded number that is no longer in that list
  /// would send a reader's money somewhere nothing is watching. It exists
  /// only so a build can keep working through an outage, and only if whoever
  /// makes that build knows the number is still one of ours:
  ///
  /// ```
  /// flutter build apk --dart-define=TMCELL_RECEIVER_PHONE=+993XXXXXXXX
  /// ```
  static const String fallbackReceiverPhone =
      String.fromEnvironment('TMCELL_RECEIVER_PHONE');

  /// What a reader may send in one transfer. TMCELL's own transfer service
  /// sets the floor and ceiling; these are the round amounts inside it.
  static const List<int> amounts = [20, 30, 40, 50];

  /// The SMS the messaging app opens with: `<receiver>   <amount>`.
  ///
  /// [receiver] is whatever the backend gave the screen, not the constant
  /// above — that one is only the fallback.
  ///
  /// The separator is spaces, and the body is percent-encoded exactly once —
  /// encoding an already-encoded string is what makes the messaging app show
  /// a literal `%2B` instead of a `+`, and `%20` decodes more reliably across
  /// messaging apps than the `+` that `Uri(queryParameters:)` would emit.
  static Uri transferSms({required String receiver, required int amount}) =>
      Uri.parse(
        'sms:$smsShortCode?body='
        '${Uri.encodeComponent('$receiver   $amount')}',
      );
}
