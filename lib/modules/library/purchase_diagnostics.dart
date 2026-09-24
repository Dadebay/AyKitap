import 'package:flutter/foundation.dart';

import '../../core/models/library_book.dart';

/// Purple diagnostics for a reported "I bought one book, but the Satyn
/// alnanlar tab shows a different one".
///
/// Three things could produce that, and they need different fixes, so each
/// one is printed separately rather than guessed at:
///
/// 1. The **wrong id was bought** — the screen sent a book id that isn't the
///    book the reader tapped. [logBookPurchase] prints the id and name at the
///    moment of purchase, so it can be compared with the cover that was
///    tapped.
/// 2. The **backend's list is wrong** — `GET /books/all?bought=true` answers
///    with a book that was never bought. [logPurchasedShelf] prints the
///    server's list in full, and the difference against what the app had
///    cached locally.
/// 3. The **grid renders the wrong cover** — server and cache both correct,
///    but the row on screen shows another book. That one is only visible by
///    comparing the printed list against what the tab actually displays,
///    which is why every row is printed with its position.
const _purple = '\x1B[35m\x1B[1m';
const _reset = '\x1B[0m';

/// Every key `GET /books/:id` actually answers with, values included.
///
/// Added because the backend developer's reading of the purchase mismatch is
/// that `/users/buy-book/:id` wants a **book_translate_id**, not the
/// `book.id` the app has always sent. The app parses neither — nothing in
/// `BookDetail` or `LibraryBook` carries a translate id — so before changing
/// what is sent, this says whether the response even offers one, and under
/// which key. `bookFiles` rows are printed too: a per-translation file row is
/// where such an id would most plausibly live.
void logBookDetailRawJson(int requestedId, Map<String, dynamic> json) {
  if (!kDebugMode) return;
  debugPrint('$_purple💜 GET /books/$requestedId — raw response keys:$_reset');
  json.forEach((key, value) {
    // Long prose (description) and nested lists would bury the id-shaped
    // fields this is here to find.
    final shown = value is List
        ? '[${value.length} item(s)]'
        : (value is String && value.length > 60
            ? '${value.substring(0, 60)}…'
            : '$value');
    debugPrint('$_purple💜   $key = $shown$_reset');
  });
  final files = json['bookFiles'];
  if (files is List) {
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (file is! Map) continue;
      final pairs = file.entries
          .where((e) => e.value is! String || '${e.value}'.length <= 60)
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      debugPrint('$_purple💜   bookFiles[$i]: $pairs$_reset');
    }
  }
}

/// One line at the moment a book is bought from the balance.
void logBookPurchase({
  required String step,
  required int bookId,
  required int bookFileId,
  required String bookName,
}) {
  if (!kDebugMode) return;
  // Both ids, because they are separate id spaces that overlap — the whole
  // reason the wrong book was bought. The path segment is the file id.
  debugPrint('$_purple💜 BUY $step — bookFileId=$bookFileId '
      '(book id=$bookId) "$bookName"$_reset');
}

/// The whole "Satyn alnanlar" shelf as the backend answered it, plus how it
/// differs from the ids the app had cached before this fetch.
///
/// [cachedIds] is read *before* `replacePurchased` overwrites it — otherwise
/// the two would always agree and the comparison would say nothing.
void logPurchasedShelf({
  required List<LibraryBook> books,
  required Set<int> cachedIds,
}) {
  if (!kDebugMode) return;
  debugPrint('$_purple💜 PURCHASED shelf — GET /books/all?bought=true '
      'returned ${books.length} book(s)$_reset');
  for (var i = 0; i < books.length; i++) {
    final book = books[i];
    debugPrint('$_purple💜   #${i + 1} id=${book.id} "${book.name}" '
        'price=${book.price}$_reset');
  }
  final serverIds = books.map((b) => b.id).toSet();
  final onlyOnServer = serverIds.difference(cachedIds);
  final onlyInCache = cachedIds.difference(serverIds);
  if (onlyOnServer.isNotEmpty) {
    // Normal right after a purchase — the book just bought. Anything else
    // here is a book the backend thinks was bought and the app never saw.
    debugPrint('$_purple💜   on server, not in local cache: '
        '${onlyOnServer.join(", ")}$_reset');
  }
  if (onlyInCache.isNotEmpty) {
    // The app believed these were bought and the backend disagrees — a
    // purchase that never registered, or a stale cache from another account.
    debugPrint('$_purple💜   in local cache, not on server: '
        '${onlyInCache.join(", ")}$_reset');
  }
  if (onlyOnServer.isEmpty && onlyInCache.isEmpty) {
    debugPrint('$_purple💜   local cache agrees with the server$_reset');
  }
}
