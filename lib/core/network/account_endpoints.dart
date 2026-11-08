/// Signed-in-user account/activity endpoints — [BalanceLogApiService],
/// [GiftApiService], [AppActivityApiService], [ContactApiService],
/// [UserNotesApiService]. Split out of the former single
/// `api_endpoints.dart` by which service owns each route. Paths are
/// relative to [ApiConfig.baseUrl].
class AccountEndpoints {
  AccountEndpoints._();

  /// GET — the signed-in user's balance activity, including top-ups and
  /// book purchases.
  static const String balanceLogs = '/users/balance-logs';

  /// GET `?phone=` — whether [phone] belongs to a registered user. Backs
  /// [SendGiftSheet]'s live lookup as the recipient's number is typed, gating
  /// [sendToFriend] on a hit.
  static const String isUserExists = '/users/is-user-exists';

  /// POST `{phone, amount}` — moves `amount` TMT from the signed-in user's
  /// balance to the registered user at `phone`. See [isUserExists].
  static const String sendToFriend = '/users/send-to-friend';

  /// POST — foreground seconds spent anywhere in the app (`{"seconds": 60}`,
  /// 1..7200), which the admin dashboard's "most active users" widget is
  /// built from. Distinct from `StreakEndpoints.streakReport`, which counts
  /// *reading* time only.
  ///
  /// The server accumulates whatever it receives into the Ashgabat calendar
  /// day it arrives on, with no de-duplication — so a report whose response
  /// never came back must not be repeated (it may well have landed). Two
  /// server-side guards the client has to know about: reports closer
  /// together than 15s still answer 200 but are *not* counted, and a day's
  /// total is capped at 86400s. See [AppActivityService], which is built
  /// around both.
  static const String appActivity = '/users/app-activity';

  /// GET — the "Biz bilen habarlaş" contact card (Telegram, phone, email,
  /// privacy/terms links).
  static const String contacts = '/contacts';

  /// GET — the signed-in user's notes/highlights, each with the source
  /// book's name/cover; POST — captures a new one. Backs Profile's "Notlar"
  /// list ([UserNotesApiService]).
  static const String userNotes = '/users/notes';

  /// PATCH/DELETE — updates or removes one note by id.
  static String userNoteById(int id) => '/users/notes/$id';
}
