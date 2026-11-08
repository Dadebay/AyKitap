/// One row from `GET /users/notes` — the signed-in user's real, backend-
/// persisted notes/highlights. Distinct from [ReadingNote], which is the
/// reader's own local highlight system (colour + EPUB CFI, so it can redraw
/// the highlight on the page) — this backend shape has neither, so it can
/// only back a plain list (Profile's "Notlar"), not in-book highlight
/// rendering.
class UserNote {
  final int id;
  final String note;
  final String? snippet;
  final int bookId;
  final String bookName;
  final String? bookImage;
  final DateTime createdAt;

  const UserNote({
    required this.id,
    required this.note,
    this.snippet,
    required this.bookId,
    required this.bookName,
    this.bookImage,
    required this.createdAt,
  });

  factory UserNote.fromJson(Map<String, dynamic> json) => UserNote(
        id: json['id'] as int,
        note: json['note'] as String? ?? '',
        snippet: json['snippet'] as String?,
        bookId: json['book_id'] as int,
        bookName: json['book_name'] as String? ?? '',
        bookImage: json['book_image'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  UserNote copyWith({String? note, String? snippet}) => UserNote(
        id: id,
        note: note ?? this.note,
        snippet: snippet ?? this.snippet,
        bookId: bookId,
        bookName: bookName,
        bookImage: bookImage,
        createdAt: createdAt,
      );
}
