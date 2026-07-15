import 'book.dart';

/// A highlight/note captured while reading (TZ 8.4). The book it belongs to
/// isn't stored directly (Book/MockData aren't JSON-friendly) — instead
/// [bookSeed]/[bookIndex] deterministically regenerate the exact same Book
/// via MockData.generateBooks, since that function is a pure mapping from
/// (seed, index) to a Book.
class ReadingNote {
  final String id;
  final String text;
  final int bookSeed;
  final int bookIndex;
  final String bookTitle;
  final DateTime createdAt;

  const ReadingNote({
    required this.id,
    required this.text,
    required this.bookSeed,
    required this.bookIndex,
    required this.bookTitle,
    required this.createdAt,
  });

  Book get book => MockData.generateBooks(bookIndex + 1, seed: bookSeed)[bookIndex];

  ReadingNote copyWith({String? text}) => ReadingNote(
    id: id,
    text: text ?? this.text,
    bookSeed: bookSeed,
    bookIndex: bookIndex,
    bookTitle: bookTitle,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'bookSeed': bookSeed,
    'bookIndex': bookIndex,
    'bookTitle': bookTitle,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReadingNote.fromJson(Map<String, dynamic> json) => ReadingNote(
    id: json['id'] as String,
    text: json['text'] as String,
    bookSeed: json['bookSeed'] as int,
    bookIndex: json['bookIndex'] as int,
    bookTitle: json['bookTitle'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
