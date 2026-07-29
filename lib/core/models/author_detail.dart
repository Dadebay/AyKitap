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
