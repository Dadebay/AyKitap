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

  /// GET — the signed-in user's balance activity, including top-ups and
  /// book purchases.
  static const String balanceLogs = '/users/balance-logs';

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

  /// POST `{"progress": 0..100}` — syncs the signed-in user's reading
  /// progress for [bookId] server-side. [CatalogBookDetailScreen]'s "mark
  /// as finished" flag button sends `100`; nothing else calls this yet
  /// (the readers still track progress purely on-device via prefs).
  static String bookProgress(int bookId) => '/books/$bookId/progress';

  /// POST — likes [bookId] for the signed-in user.
  static String likeBook(String bookId) => '/books/$bookId/like';

  /// DELETE — un-likes [bookId] for the signed-in user.
  static String unlikeBook(String bookId) => '/books/unlike/$bookId';

  /// DELETE — removes a book from the signed-in user's purchased library.
  static String removeBoughtBook(int bookId) => '/books/bought/$bookId';

  /// POST — buys [bookId] for the signed-in user, paying from the balance.
  /// 201 on success, its `data` a presigned download link for the purchased
  /// file (same `{url, size, name, lastModified}` shape as [bookFile]) — a
  /// bonus the purchase flow doesn't currently use, but is there if a later
  /// change wants to skip the follow-up [bookFile] call right after buying.
  /// 400 with `{"message": "You do not have enough balance", ...}` when the
  /// balance falls short.
  static String buyBook(int bookId) => '/users/buy-book/$bookId';

  /// GET — a presigned download link for one book file. The `?filename=`
  /// value is the `file_key` straight off `GET /books/:id`'s `bookFiles[]`
  /// (`/private/....pdf`); Dio URL-encodes it as a query parameter.
  ///
  /// The returned URL points at the media host (port 9000, not the API's
  /// 4000) and carries an `X-Amz-Expires=600` signature — it is valid for
  /// ~10 minutes and must never be persisted. [BookDownloadService] fetches
  /// a fresh one for every download.
  static const String bookFile = '/books/file';

  // ── Book languages ───────────────────────────────────────────────────
  /// GET — the languages books can be written in, each with its name in all
  /// three UI languages. Backs the Filtr sahypasy's "Dil" section; the
  /// picked row's id goes back to [booksAll] as `language_id`.
  static const String bookLanguages = '/book-languages';

  // ── Collections ──────────────────────────────────────────────────────
  /// GET — themed shelves ("Täze gelenler", ...) with their books, rendered
  /// as Home's stacked collection sections.
  static const String collectionsAll = '/collections/all';

  // ── Genres ───────────────────────────────────────────────────────────
  /// GET — genres, optionally filtered by `?parent_id=`. Backs Search's
  /// genre chip row — tapping one opens `GET /books/all?genre_id=`.
  static const String genresAll = '/genres/all';

  // ── Authors ──────────────────────────────────────────────────────────
  /// GET — one author's full detail (name, image, bio). Backs
  /// [CatalogAuthorDetailScreen], reached from a `type: "author"`
  /// collection's avatar row.
  static String authorById(int id) => '/authors/$id';

  /// GET — searches authors by name (`?search=`), paginated, returning each
  /// match's id/image/name/`book_count` directly. Backs Search's "Ýazar"
  /// mode — dedicated author matching, unlike [booksAll]'s `authors=` param
  /// (which matches against each book's author list and hands back books,
  /// not authors).
  static const String authorsSearch = '/authors/search';

  // ── Payments ─────────────────────────────────────────────────────────
  /// GET — the subscription tariffs (`month_count`/`price`/`actual_price`)
  /// [SubscriptionScreen] lists as plans.
  static const String tariffs = '/payments/tariffs';

  /// POST — buys tariff [tariffId] for the signed-in user, paying from the
  /// balance. Same shape as [buyBook]: 201 on success (money moved
  /// server-side), 400 `{"message": "You do not have enough balance", ...}`
  /// when it doesn't cover the price. What this actually *grants* — the
  /// active-until date — isn't in this response or `/users/me` yet, so
  /// [SubscriptionService] still tracks that on-device.
  static String buySubscription(int tariffId) => '/users/buy-subscription/$tariffId';

  /// GET — banks offered for card payment, shown in the bank-selection
  /// sheet before checkout.
  static const String banks = '/payments/banks';

  /// POST `{amount, bank_id}` — creates a balance top-up order. 201's
  /// `data.invoiceUrl` is the bank's online payment page
  /// ([PaymentWebViewScreen] opens it in-app); the balance itself only
  /// moves once the bank confirms the payment server-side, so the caller
  /// re-reads `/users/me` after the webview closes rather than trusting
  /// anything client-side. This is the *only* bank-card money-in path —
  /// there is no separate "pay for this subscription/book via bank"
  /// endpoint; [buySubscription]/[BookPurchaseApiService.buy] both spend
  /// from whatever balance this has put there.
  static const String paymentOrders = '/payments/orders';

  /// GET — the signed-in user's own bank-card top-up orders, newest first
  /// (each with its bank and amount) — [BalanceScreen]'s "card payments"
  /// section.
  static const String paymentsMy = '/payments/my';

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

  /// DELETE — removes one of the signed-in user's own book requests.
  static String suggestById(int id) => '/suggests/$id';

  /// POST — a free-text bug/problem report.
  static const String problems = '/problems';

  // ── Streaks ──────────────────────────────────────────────────────────
  /// POST — reports reading activity (`seconds`/`pages` deltas since the
  /// last successful report) toward today's streak goal. Call every 60s
  /// during active reading, plus once on pause/background/close with the
  /// residual seconds. The server credits whatever it receives to the
  /// Ashgabat calendar day *at the moment it's received* — no back-dating,
  /// so a report that had to be buffered offline should be flushed as soon
  /// as the connection returns rather than held any longer.
  static const String streakReport = '/streaks/report';

  /// GET — everything the Streak screen needs in one call: today/week/month
  /// totals, streak counts, and the reward rules (so their text isn't
  /// hard-coded on-device).
  static const String streakMe = '/streaks/me';

  /// GET — paginated daily reading history (`?page=&limit=`), newest day
  /// first.
  static const String streakHistory = '/streaks/history';
}
