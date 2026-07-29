/// Every backend endpoint path the app calls, in one place. Add new routes
/// here as the backend grows rather than inlining a path string at the call
/// site — this file is meant to stay the single index of the API surface.
/// Paths are relative to [ApiConfig.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth (TZ 2.1/2.3) ────────────────────────────────────────────────
  static const String sendCode = '/users/send-code';
  static const String verifyLogin = '/users/verify-login';
  static const String logout = '/users/logout';

  // ── Users ────────────────────────────────────────────────────────────
  /// PATCH — partial update of the signed-in user (e.g. `{"username": ...}`).
  static const String updateProfile = '/users';

  /// GET — the signed-in user's own record.
  static const String me = '/users/me';

  /// PATCH — pushes the device's current FCM token to the backend.
  static const String fcmToken = '/users/fcm-token';

  /// POST — redeems a promo code (`{"promo_code": "..."}`); the backend
  /// credits the balance server-side and returns an empty `data: {}` — the
  /// caller must follow up with [me] to pick up the new balance.
  static const String promoCodes = '/users/promo-codes';

  // ── Books ────────────────────────────────────────────────────────────
  /// GET — paginated real book catalogue, filtered by query params
  /// (`my_books`, `bought`, `wants_to`, `search`, `genre_id`, ...). Backs
  /// [LibraryScreen]'s reading/purchased/liked tabs; Search still runs on
  /// `MockData`'s locally-generated `Book.id`s (`book_3_7`, ...), so
  /// [likeBook]/[unlikeBook] below only actually persist for ids that came
  /// from here.
  static const String booksAll = '/books/all';

  /// GET — one book's full detail (description, genres, authors, files).
  /// Backs [CatalogBookDetailScreen] — a real id from [booksAll],
  /// [collectionsAll], or a banner's `book_id`.
  static String bookById(int id) => '/books/$id';

  /// POST — likes [bookId] for the signed-in user.
  static String likeBook(String bookId) => '/books/$bookId/like';

  /// DELETE — un-likes [bookId] for the signed-in user.
  static String unlikeBook(String bookId) => '/books/unlike/$bookId';

  // ── Collections ──────────────────────────────────────────────────────
  /// GET — themed shelves ("Täze gelenler", ...) with their books, rendered
  /// as Home's stacked collection sections.
  static const String collectionsAll = '/collections/all';

  // ── Authors ──────────────────────────────────────────────────────────
  /// GET — one author's full detail (name, image, bio). Backs
  /// [CatalogAuthorDetailScreen], reached from a `type: "author"`
  /// collection's avatar row.
  static String authorById(int id) => '/authors/$id';

  // ── Payments ─────────────────────────────────────────────────────────
  /// GET — the subscription tariffs (`month_count`/`price`/`actual_price`)
  /// [SubscriptionScreen] lists as plans.
  static const String tariffs = '/payments/tariffs';

  /// GET — banks offered for card payment, shown in the bank-selection
  /// sheet before checkout.
  static const String banks = '/payments/banks';

  /// POST — starts a bank-card checkout, returning the bank's online
  /// payment page URL. UNCONFIRMED: no Postman screenshot for this call
  /// exists yet (unlike every other endpoint in this file) — path/body
  /// guessed from this API's own naming plus this app's Ter-market sibling
  /// project's equivalent `initiate/` call. Confirm the real contract
  /// (path, body shape, response field) before relying on this.
  static const String subscribeInitiate = '/payments/subscribe';

  // ── Banners ──────────────────────────────────────────────────────────
  /// GET — the active promo banners for Home's [BannerCarousel], public
  /// (no auth needed).
  static const String banners = '/banners';

  // ── Contact ──────────────────────────────────────────────────────────
  /// GET — the "Biz bilen habarlaş" contact card (Telegram, phone, email,
  /// privacy/terms links).
  static const String contacts = '/contacts';

  // ── Notes ────────────────────────────────────────────────────────────
  /// GET — the signed-in user's notes/highlights, each with the source
  /// book's name/cover; POST — captures a new one. Backs Profile's "Notlar"
  /// list ([UserNotesApiService]).
  static const String userNotes = '/users/notes';

  /// PATCH/DELETE — updates or removes one note by id.
  static String userNoteById(int id) => '/users/notes/$id';

  // ── Feedback ─────────────────────────────────────────────────────────
  /// POST — a "kitap haýyşy" (book request/suggestion).
  static const String suggests = '/suggests';

  /// GET — the signed-in user's own book requests, with review status.
  static const String suggestsMy = '/suggests/my';

  /// POST — a free-text bug/problem report.
  static const String problems = '/problems';
}
