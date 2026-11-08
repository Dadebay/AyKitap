/// A saved reading position (TZ §12.1). Unlike [ReadingNote], a bookmark
/// points at a place rather than quoting text, so it stores the EPUB CFI to
/// jump back to plus enough context (book title, chapter, progress) for the
/// profile's cross-book list to be readable on its own.
class Bookmark {
  final String id;

  /// The reader's book id (`stableBookKey(Book.id)`), used to scope a book's
  /// own bookmark list.
  final int bookId;
  final String bookTitle;

  /// EPUB CFI of the bookmarked page — hand to `EpubController.display`.
  final String cfi;

  /// Chapter name at the time it was saved; may be empty for pages that
  /// aren't in the table of contents (a cover, say).
  final String chapterTitle;

  /// Reading progress 0.0–1.0, shown as a percentage in the lists.
  final double progress;

  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.cfi,
    required this.chapterTitle,
    required this.progress,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'cfi': cfi,
        'chapterTitle': chapterTitle,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        bookId: json['bookId'] as int,
        bookTitle: json['bookTitle'] as String? ?? '',
        cfi: json['cfi'] as String,
        chapterTitle: json['chapterTitle'] as String? ?? '',
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
