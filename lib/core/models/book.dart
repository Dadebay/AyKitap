import 'package:flutter/material.dart';

/// Domain models shared across Home / Search / Filter / Library /
/// Book Detail / Author screens. The mock data that populates them lives in
/// `core/data/mock/mock_data.dart` — kept separate so this file only ever
/// changes when the shape of a book/author/series/collection changes, not
/// when the sample catalogue does.

enum BookFormat { epub, pdf, mobi, cbz }

extension BookFormatLabel on BookFormat {
  String get label {
    switch (this) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.mobi:
        return 'MOBI';
      case BookFormat.cbz:
        return 'CBZ';
    }
  }
}

/// A HomeScreen horizontal-list section: a title and, for the genre rows,
/// a one-line description shown underneath it.
class HomeSection {
  final String title;
  final String? subtitle;
  const HomeSection({required this.title, this.subtitle});
}

/// A themed "big card" shelf on HomeScreen — Kolleksiýalar row — each one
/// holding its own 50-book set (e.g. "New York Times Bestsellers").
class BookCollection {
  final String title;
  final String emoji;
  final List<Color> gradient;
  final List<Book> books;
  const BookCollection({required this.title, required this.emoji, required this.gradient, required this.books});
}

/// A themed book series ("Seriýa") — a large image card on HomeScreen, each
/// wrapping its own ordered set of books (part 1, part 2, …).
class BookSeries {
  final String title;
  final String coverImage;
  final List<Book> books;
  const BookSeries({required this.title, required this.coverImage, required this.books});

  int get bookCount => books.length;
}

class Author {
  final String id;
  final String name;
  final Color color;
  final String bio;

  const Author({required this.id, required this.name, required this.color, required this.bio});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color.toARGB32(), 'bio': bio};

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        bio: json['bio'] as String,
      );
}

class Book {
  final String id;
  final String title;
  final Author author;
  final Color coverColor;
  final String coverImage;
  final BookFormat format;
  final List<String> genres;
  final String publisher;
  final int pages;
  final int readCount;
  final int purchaseCount;
  final int priceManat;
  final bool isFree;
  final String synopsis;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverColor,
    required this.coverImage,
    required this.format,
    required this.genres,
    required this.publisher,
    required this.pages,
    required this.readCount,
    required this.purchaseCount,
    required this.priceManat,
    this.isFree = false,
    required this.synopsis,
  });

  /// Round-trips a mock [Book] through JSON for on-device persistence (e.g.
  /// [PurchasedBooksStore]) — there's no backend to re-fetch a book by id
  /// from, and the same id can't be regenerated later since [MockData]'s
  /// seeded generators don't form a stable global registry.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author.toJson(),
        'coverColor': coverColor.toARGB32(),
        'coverImage': coverImage,
        'format': format.name,
        'genres': genres,
        'publisher': publisher,
        'pages': pages,
        'readCount': readCount,
        'purchaseCount': purchaseCount,
        'priceManat': priceManat,
        'isFree': isFree,
        'synopsis': synopsis,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        title: json['title'] as String,
        author: Author.fromJson(json['author'] as Map<String, dynamic>),
        coverColor: Color(json['coverColor'] as int),
        coverImage: json['coverImage'] as String,
        format: BookFormat.values.firstWhere((f) => f.name == json['format']),
        genres: (json['genres'] as List).cast<String>(),
        publisher: json['publisher'] as String,
        pages: json['pages'] as int,
        readCount: json['readCount'] as int,
        purchaseCount: json['purchaseCount'] as int,
        priceManat: json['priceManat'] as int,
        isFree: json['isFree'] as bool,
        synopsis: json['synopsis'] as String,
      );
}
