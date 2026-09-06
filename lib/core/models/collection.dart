import 'library_book.dart';

/// Whether a [Collection] is a themed set of books or a themed set of
/// authors ("Rus Awtorlar", ...) — governs whether Home renders it as a
/// book row/card or an author-avatar row, independent of [CollectionCardType].
enum CollectionType { book, author }

/// Which visual [Collection] renders as on Home when [CollectionType.book]:
/// `card_1` a title + horizontally-scrolling row of individual book cards,
/// `card_2` a single ranked-shelf card (banner + top books), `card_3` a
/// single big series-style image card, and `card_4` a numbered horizontal
/// bestseller row. Unrecognized values fall back to
/// `card1` rather than throwing, so a new backend card type doesn't crash
/// the app — it just renders as the plain row until this is taught about it.
enum CollectionCardType { card1, card2, card3, card4 }

/// One row from `GET /collections/all` — a themed shelf on Home
/// ("Täze gelenler", "Hepdelik iň köp okalanlar", "Rus Awtorlar", ...).
class Collection {
  final int id;
  final CollectionType type;
  final CollectionCardType cardType;
  final String name;
  final String? subTitle;

  /// The collection's own banner/cover image (a raw `/public/...` path, same
  /// as [LibraryBook.image] — resolve with `ApiConfig.resolveImageUrl`).
  /// Null for plenty of rows (a `card1` row has no use for one), in which
  /// case [CatalogRankShelfCard]/[CatalogSeriesCard] fall back to the first
  /// book's own cover rather than showing nothing.
  final String? image;

  final List<LibraryBook> books;

  /// The backend's Home ordering slot — mostly just a sort key, but when
  /// several collections share the same value they're meant to sit side by
  /// side as one horizontally-scrolling row instead of each getting its own
  /// stacked section (see [HomeScreen]'s grouping).
  final int queuePosition;

  /// Only present (and only meaningful) when [type] is
  /// [CollectionType.author] — the authors this collection is themed
  /// around, rendered as an avatar row instead of [books].
  final List<LibraryBookAuthor>? authors;

  const Collection({
    required this.id,
    required this.type,
    required this.cardType,
    required this.name,
    this.subTitle,
    this.image,
    this.books = const [],
    this.queuePosition = 0,
    this.authors,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    final type = json['type'] == 'author' ? CollectionType.author : CollectionType.book;
    return Collection(
      id: json['id'] as int,
      type: type,
      cardType: _cardTypeFrom(json['card_type'] as String?),
      name: json['name'] as String? ?? '',
      subTitle: json['sub_title'] as String?,
      image: json['image'] as String?,
      queuePosition: json['queue_position'] as int? ?? 0,
      // An author-type collection's `books` array is never rendered (the
      // avatar row uses `authors` instead) — skip parsing it rather than
      // doing the work for a list nothing reads.
      books: type == CollectionType.author ? const [] : (json['books'] as List? ?? const []).map((e) => LibraryBook.fromJson(e as Map<String, dynamic>)).toList(),
      authors: (json['authors'] as List?)?.map((e) => LibraryBookAuthor.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static CollectionCardType _cardTypeFrom(String? raw) {
    switch (raw) {
      case 'card_2':
        return CollectionCardType.card2;
      case 'card_3':
        return CollectionCardType.card3;
      case 'card_4':
        return CollectionCardType.card4;
      default:
        return CollectionCardType.card1;
    }
  }
}
