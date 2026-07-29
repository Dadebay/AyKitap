import 'book.dart';
import '../data/mock/mock_data.dart';
import '../theme/highlight_colors.dart';
import '../utils/stable_hash.dart';

/// A highlight/note captured while reading (TZ 8.4).
///
/// Every note is keyed to its book by [bookId] — the same stable int the
/// reader opens with — so highlights redraw for *any* book, including the
/// user's own imported files (which no catalogue entry can regenerate).
///
/// [bookSeed]/[bookIndex] are the extra hook a *catalogue* book carries: they
/// deterministically regenerate the exact same [Book] via
/// MockData.generateBooks (a pure (seed, index) → Book mapping), which is what
/// lets the profile show the cover and offer "go to book". They're null for
/// imported files, so [book] is nullable and callers must handle its absence.
class ReadingNote {
  final String id;
  final String text;

  /// Stable key of the book this note belongs to — [stableBookKey] of the
  /// book's id/path, matching what the reader was opened with.
  final int bookId;

  /// Catalogue-book coordinates, or null for an imported file — see the class
  /// doc. When set, [book] regenerates the source Book.
  final int? bookSeed;
  final int? bookIndex;

  final String bookTitle;
  final DateTime createdAt;

  /// ARGB colour the highlight/note is painted with — see [HighlightColors].
  final int colorValue;

  /// EPUB CFI of the highlighted passage — set only for notes captured via
  /// the "Belle" (highlight) action, null for a plain "Not" (no highlight
  /// painted on the page). Lets ReaderProvider redraw the highlight the next
  /// time this book's rendition is set up; see its onEpubLoaded.
  final String? cfi;

  /// The backend `UserNote.id` this note was also persisted as via
  /// `POST /users/notes`, or null when it wasn't (the reader only calls that
  /// API when it has a real catalogue book id — see `ReaderScreen.realBookId`;
  /// the user's own imported files have no such id, so their notes stay
  /// local-only). Lets a later delete also call `DELETE /users/notes/:id`.
  final int? remoteId;

  const ReadingNote({
    required this.id,
    required this.text,
    required this.bookId,
    required this.bookTitle,
    required this.createdAt,
    this.bookSeed,
    this.bookIndex,
    this.colorValue = 0xFFFFD54F,
    this.cfi,
    this.remoteId,
  });

  /// The catalogue Book this note came from, or null for an imported file that
  /// no catalogue entry can regenerate (see the class doc).
  Book? get book {
    final seed = bookSeed;
    final index = bookIndex;
    if (seed == null || index == null) return null;
    return MockData.generateBooks(index + 1, seed: seed)[index];
  }

  ReadingNote copyWith({String? text, int? colorValue}) => ReadingNote(
    id: id,
    text: text ?? this.text,
    bookId: bookId,
    bookSeed: bookSeed,
    bookIndex: bookIndex,
    bookTitle: bookTitle,
    createdAt: createdAt,
    colorValue: colorValue ?? this.colorValue,
    cfi: cfi,
    remoteId: remoteId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'bookId': bookId,
    if (bookSeed != null) 'bookSeed': bookSeed,
    if (bookIndex != null) 'bookIndex': bookIndex,
    'bookTitle': bookTitle,
    'createdAt': createdAt.toIso8601String(),
    'colorValue': colorValue,
    if (cfi != null) 'cfi': cfi,
    if (remoteId != null) 'remoteId': remoteId,
  };

  factory ReadingNote.fromJson(Map<String, dynamic> json) {
    final seed = json['bookSeed'] as int?;
    final index = json['bookIndex'] as int?;
    return ReadingNote(
      id: json['id'] as String,
      text: json['text'] as String,
      // Notes saved before highlights were book-keyed by id carry only
      // seed/index — rebuild the same bookId the reader would use so their
      // highlights still restore.
      bookId: json['bookId'] as int? ??
          (seed != null && index != null ? stableBookKey('book_${seed}_$index') : 0),
      bookSeed: seed,
      bookIndex: index,
      bookTitle: json['bookTitle'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      colorValue: json['colorValue'] as int? ?? HighlightColors.defaultColor.toARGB32(),
      cfi: json['cfi'] as String?,
      remoteId: json['remoteId'] as int?,
    );
  }
}
