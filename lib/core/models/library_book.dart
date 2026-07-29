/// One author entry inside a [LibraryBook]'s `authors` list.
class LibraryBookAuthor {
  final int id;
  final String name;
  final String? image;

  const LibraryBookAuthor({required this.id, required this.name, this.image});

  factory LibraryBookAuthor.fromJson(Map<String, dynamic> json) => LibraryBookAuthor(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        image: json['image'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, if (image != null) 'image': image};
}

/// One book summary from the real catalogue — `GET /books/all` (via
/// [LibraryScreen]'s reading/purchased/liked tabs) and `GET /collections/all`
/// (each [Collection]'s `books`, via Home's collection sections) both return
/// this same shape. Distinct from the mock catalogue's `Book`
/// (`core/models/book.dart`), which Search/Book Detail still run on.
class LibraryBook {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int? age;
  final int? year;
  final int? pageCount;
  final int? price;
  final List<LibraryBookAuthor> authors;

  /// Only populated when fetched with `my_books=true` — how far the
  /// signed-in user has read. The backend's scale isn't pinned down by any
  /// non-null sample seen yet, so [LibraryBookCover] normalizes both a 0–1
  /// fraction and a 0–100 percentage to the same 0–1 range rather than
  /// assuming one.
  final double? progress;

  const LibraryBook({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.age,
    this.year,
    this.pageCount,
    this.price,
    this.authors = const [],
    this.progress,
  });

  String get authorNames => authors.map((a) => a.name).join(', ');

  factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        image: json['image'] as String?,
        age: json['age'] as int?,
        year: json['year'] as int?,
        pageCount: json['page_count'] as int?,
        price: json['price'] as int?,
        authors: (json['authors'] as List? ?? const [])
            .map((e) => LibraryBookAuthor.fromJson(e as Map<String, dynamic>))
            .toList(),
        progress: (json['progress'] as num?)?.toDouble(),
      );

  /// Round-trips through [fromJson] — used to persist a book locally (e.g.
  /// [DownloadedBooksStore]), not just to parse a fresh API response.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
        if (age != null) 'age': age,
        if (year != null) 'year': year,
        if (pageCount != null) 'page_count': pageCount,
        if (price != null) 'price': price,
        'authors': authors.map((a) => a.toJson()).toList(),
        if (progress != null) 'progress': progress,
      };
}
