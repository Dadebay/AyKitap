import 'package:flutter/foundation.dart';

import '../../core/models/library_book.dart';

/// Why two rows in one page of results look like the same book.
enum LookalikeReason {
  /// The same `id` came back twice — the backend handed us one book twice,
  /// which is never right.
  sameId,

  /// Different ids, but titles that a reader can't tell apart once case,
  /// stray spacing and punctuation are set aside. Often legitimate (two
  /// editions, two languages of the same work), so this is reported rather
  /// than treated as a fault.
  sameTitle,
}

/// One set of results that read as the same book.
class LookalikeGroup {
  const LookalikeGroup({
    required this.reason,
    required this.key,
    required this.books,
  });

  final LookalikeReason reason;

  /// What the group has in common — the shared id, or the normalised title.
  final String key;
  final List<LibraryBook> books;
}

/// Strips a title down to what a reader actually compares: case, leading and
/// trailing space, repeated inner spaces, and punctuation all go.
///
/// Those are exactly the differences that make two rows look identical on
/// screen while staying distinct strings to the backend — the live catalogue
/// carries titles like `'Alchemist '` and `'%100  Düşünce gücü'` with trailing
/// and doubled spaces, which would otherwise hide a genuine duplicate.
String normalizedBookTitle(String name) {
  final buffer = StringBuffer();
  var pendingSpace = false;
  for (final rune in name.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final isSeparator = char.trim().isEmpty;
    // Letters and digits only: anything else (quotes, %, #, punctuation) is
    // decoration a reader doesn't use to tell two books apart.
    final isWord = RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(char);
    if (isSeparator || !isWord) {
      pendingSpace = buffer.isNotEmpty;
      continue;
    }
    if (pendingSpace) {
      buffer.write(' ');
      pendingSpace = false;
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Every set of look-alike results in [books], most-confusing first (repeated
/// ids before merely repeated titles). Empty for a clean page.
List<LookalikeGroup> findLookalikeResults(List<LibraryBook> books) {
  final byId = <int, List<LibraryBook>>{};
  final byTitle = <String, List<LibraryBook>>{};
  for (final book in books) {
    byId.putIfAbsent(book.id, () => []).add(book);
    byTitle.putIfAbsent(normalizedBookTitle(book.name), () => []).add(book);
  }

  final groups = <LookalikeGroup>[
    for (final entry in byId.entries)
      if (entry.value.length > 1)
        LookalikeGroup(
          reason: LookalikeReason.sameId,
          key: '${entry.key}',
          books: entry.value,
        ),
  ];
  for (final entry in byTitle.entries) {
    // A blank normalised title (a name that was only punctuation) says
    // nothing about whether two books match.
    if (entry.key.isEmpty || entry.value.length < 2) continue;
    // Already reported as a repeated id — don't say the same thing twice.
    if (entry.value.map((b) => b.id).toSet().length < 2) continue;
    groups.add(LookalikeGroup(
      reason: LookalikeReason.sameTitle,
      key: entry.key,
      books: entry.value,
    ));
  }
  return groups;
}

/// The titles a reader actually reported as repeating, 14.09.2026 — plus the
/// Spy×Family manga series, which was reported as the *expected* kind of
/// repetition (a series really does have many similarly-named volumes) and is
/// watched here only so it can be told apart from the rest.
///
/// Matched loosely on purpose: every word of the entry has to appear in the
/// title, in any order, so `'spy family'` still catches
/// `'Spy x Family, Vol. 3'`. Kept as data rather than hard-coded into the log
/// so the next report only has to add a line.
const watchedBookTitles = <String>[
  'İçimizdeki çocuk',
  'Beyaz leke',
  'Гордые души',
  'Veyl',
  'Сила уверенности в себе',
  'spy family',
];

Set<String> _titleWords(String title) =>
    normalizedBookTitle(title).split(' ').where((w) => w.isNotEmpty).toSet();

/// Whether [bookName] is one of the [watchedBookTitles] — all of the watched
/// entry's words present in the name, in any order.
@visibleForTesting
bool matchesWatchedTitle(String bookName, String watched) {
  final wanted = _titleWords(watched);
  if (wanted.isEmpty) return false;
  return wanted.difference(_titleWords(bookName)).isEmpty;
}

/// Prints where each reported title turned up in this page of results —
/// position, id and page — in debug builds only.
///
/// This is the half of the diagnosis [logLookalikeResults] can't give. A
/// reader saying "these books keep coming back" may be seeing the same row
/// twice (a real duplicate, which the look-alike log catches), or the same
/// book arriving once per page as they scroll, or simply a book that sits
/// near the top of whatever order the grid is in that day and so greets them
/// on every visit. Those look identical on screen and need different fixes,
/// and only the position and page tell them apart.
void logWatchedTitleSightings({
  required String query,
  required int page,
  required List<LibraryBook> books,
}) {
  if (!kDebugMode) return;
  for (var i = 0; i < books.length; i++) {
    final book = books[i];
    final watched = watchedBookTitles
        .where((w) => matchesWatchedTitle(book.name, w))
        .toList();
    if (watched.isEmpty) continue;
    debugPrint(
      '\x1B[36m\x1B[1m👁 SEARCH watched title — "${book.name}" id=${book.id} '
      'at #${i + 1} of ${books.length} (query="$query" page=$page, '
      'matched: ${watched.join(", ")})\x1B[0m',
    );
  }
}

/// Prints one coloured line per look-alike group, in debug builds only.
///
/// Added for a reported "the search results look like the same book over and
/// over" — a catalogue scan found no repeated ids in `GET /books/all`, so the
/// next time it happens this is what says whether the page really did carry a
/// book twice, and under which query. Nothing is logged for a clean page, so
/// its silence is itself the answer.
void logLookalikeResults({
  required String query,
  required int page,
  required List<LibraryBook> books,
}) {
  if (!kDebugMode) return;
  final groups = findLookalikeResults(books);
  if (groups.isEmpty) return;
  for (final group in groups) {
    final what = group.reason == LookalikeReason.sameId
        ? 'SAME ID ${group.key}'
        : 'SAME TITLE "${group.key}"';
    final rows = group.books.map((b) => 'id=${b.id} "${b.name}"').join('  |  ');
    debugPrint(
      '\x1B[33m\x1B[1m⚠ SEARCH look-alike — $what '
      '(query="$query" page=$page, ${group.books.length} rows): $rows\x1B[0m',
    );
  }
}
