/// One row from `GET /suggests/my` — a "kitap haýyşy" (book request) the
/// signed-in user sent, with the backend's review status attached.
class BookSuggestion {
  final int id;
  final String name;
  final String author;
  final String? description;
  final String language;
  final String status;
  final String? rejectedReason;
  final DateTime createdAt;

  const BookSuggestion({
    required this.id,
    required this.name,
    required this.author,
    this.description,
    required this.language,
    required this.status,
    this.rejectedReason,
    required this.createdAt,
  });

  factory BookSuggestion.fromJson(Map<String, dynamic> json) => BookSuggestion(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        author: json['author'] as String? ?? '',
        description: json['description'] as String?,
        language: json['language'] as String? ?? '',
        status: json['status'] as String? ?? 'new',
        rejectedReason: json['rejected_reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
