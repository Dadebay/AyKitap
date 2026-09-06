/// The `data` payload of `GET /authors/:id` — shown in
/// [CatalogAuthorDetailScreen], reached by tapping an author avatar in one
/// of Home's `type: "author"` collections.
class AuthorDetail {
  final int id;
  final String name;
  final String? image;
  final String? bio;

  const AuthorDetail({required this.id, required this.name, this.image, this.bio});

  factory AuthorDetail.fromJson(Map<String, dynamic> json) => AuthorDetail(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        image: json['image'] as String?,
        bio: json['bio'] as String?,
      );
}

/// One row from `GET /authors/search` — backs [SearchScreen]'s "Awtor" mode.
/// Distinct from [AuthorDetail]: no `bio` (this is a search hit, not the
/// full detail page), but it does carry [bookCount], which nothing derived
/// from `GET /books/all` results could give for free.
class AuthorSearchResult {
  final int id;
  final String name;
  final String? image;
  final int bookCount;

  const AuthorSearchResult({required this.id, required this.name, this.image, this.bookCount = 0});

  factory AuthorSearchResult.fromJson(Map<String, dynamic> json) => AuthorSearchResult(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        image: json['image'] as String?,
        // The backend sends this as a numeric-looking string (`"6"`), not a
        // JSON number — `num.tryParse` handles both just in case that ever
        // changes.
        bookCount: num.tryParse(json['book_count']?.toString() ?? '')?.toInt() ?? 0,
      );
}
