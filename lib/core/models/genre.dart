/// One row from `GET /genres/all` — a book genre/category
/// ("Roman", "Hekaýa", "Goşgy", ...), optionally nested under a parent.
class Genre {
  final int id;
  final int? parentId;
  final int? position;
  final String name;

  const Genre({
    required this.id,
    this.parentId,
    this.position,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as int,
        parentId: json['parent_id'] as int?,
        position: json['position'] as int?,
        name: json['name'] as String? ?? '',
      );
}
