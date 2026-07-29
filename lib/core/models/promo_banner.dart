/// One row from `GET /banners` — the Home screen's promo carousel.
/// Named `PromoBanner` rather than `Banner` to avoid colliding with
/// Flutter's own `Banner` widget.
class PromoBanner {
  final int id;
  final String name;
  final String websiteImage;
  final String mobileImage;
  final String? link;
  /// When present, tapping the banner should open this book's detail page
  /// ([CatalogBookDetailScreen]) instead of (or in addition to) [link].
  final int? bookId;
  final bool isActive;
  final int order;

  const PromoBanner({
    required this.id,
    required this.name,
    required this.websiteImage,
    required this.mobileImage,
    this.link,
    this.bookId,
    required this.isActive,
    required this.order,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        websiteImage: json['website_image'] as String? ?? '',
        mobileImage: json['mobile_image'] as String? ?? '',
        link: json['link'] as String?,
        bookId: json['book_id'] as int?,
        isActive: json['is_active'] as bool? ?? true,
        order: json['order'] as int? ?? 0,
      );
}
