import 'library_book.dart';

class BookDetailGenre {
  final int id;
  final String name;
  const BookDetailGenre({required this.id, required this.name});

  factory BookDetailGenre.fromJson(Map<String, dynamic> json) =>
      BookDetailGenre(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
      );
}

/// One entry in a [BookDetail]'s `bookFiles` — the backend hasn't given us
/// a download endpoint for these yet (`file_key` looks like an internal
/// storage path, not a servable URL), so this is captured for completeness
/// but [CatalogBookDetailScreen] doesn't do anything with it yet.
class BookFile {
  final int id;
  final String fileKey;
  final String fileFormat;
  final int fileSize;
  const BookFile(
      {required this.id,
      required this.fileKey,
      required this.fileFormat,
      required this.fileSize});

  factory BookFile.fromJson(Map<String, dynamic> json) => BookFile(
        id: json['id'] as int,
        fileKey: json['file_key'] as String? ?? '',
        fileFormat: json['file_format'] as String? ?? '',
        fileSize: json['file_size'] as int? ?? 0,
      );
}

/// The `data` payload of `GET /books/:id` — the full detail view of a real
/// catalogue book. Distinct from [LibraryBook] (the lighter summary shape
/// `/books/all` and `/collections/all` rows use) and the mock catalogue's
/// `Book` (`core/models/book.dart`), which Search/Home's non-collection
/// sections still run on.
class BookDetail {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int? age;
  final int? year;
  final int? pageCount;
  final int? price;
  final int? languageId;
  final int readCount;
  final int soldCount;

  /// `is_subscription_only` — readable through a subscription but never
  /// sold on its own, so no "Satyn al" anywhere for it.
  final bool isSubscriptionOnly;
  final double? progress;
  final List<BookDetailGenre> genres;
  final List<LibraryBookAuthor> authors;
  final List<BookFile> bookFiles;

  const BookDetail({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.age,
    this.year,
    this.pageCount,
    this.price,
    this.languageId,
    this.readCount = 0,
    this.soldCount = 0,
    this.isSubscriptionOnly = false,
    this.progress,
    this.genres = const [],
    this.authors = const [],
    this.bookFiles = const [],
  });

  String get authorNames => authors.map((a) => a.name).join(', ');

  factory BookDetail.fromJson(Map<String, dynamic> json) => BookDetail(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        image: json['image'] as String?,
        age: json['age'] as int?,
        year: json['year'] as int?,
        pageCount: json['page_count'] as int?,
        price: json['price'] as int?,
        languageId: _parseLanguageId(json),
        readCount: json['read_count'] as int? ?? 0,
        soldCount: json['sold_count'] as int? ?? 0,
        isSubscriptionOnly: json['is_subscription_only'] == true,
        progress: _parseProgress(json['progress']),
        genres: (json['genres'] as List? ?? const [])
            .map((e) => BookDetailGenre.fromJson(e as Map<String, dynamic>))
            .toList(),
        authors: (json['authors'] as List? ?? const [])
            .map((e) => LibraryBookAuthor.fromJson(e as Map<String, dynamic>))
            .toList(),
        bookFiles: (json['bookFiles'] as List? ?? const [])
            .map((e) => BookFile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static int? _parseLanguageId(Map<String, dynamic> json) {
    final language = json['language'];
    final raw = json['language_id'] ??
        json['book_language_id'] ??
        (language is Map ? language['id'] : null);
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _parseProgress(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
