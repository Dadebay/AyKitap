import 'package:flutter/material.dart';

/// Mock domain models shared across Home / Search / Filter / Library /
/// Book Detail / Author screens until the real backend API is wired up.

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

class MockData {
  MockData._();

  static const _coverColors = [
    Color(0xFF3B4A6B),
    Color(0xFF4A3B6B),
    Color(0xFF6B3B3B),
    Color(0xFF3B6B4A),
    Color(0xFF6B5B3B),
    Color(0xFF3B5B6B),
    Color(0xFF5B3B6B),
    Color(0xFF6B3B5B),
  ];

  static final authors = List.generate(25, (i) {
    return Author(
      id: 'author_$i',
      name: _authorNames[i % _authorNames.length],
      color: _coverColors[i % _coverColors.length],
      bio:
          'Türkmen we dünýä edebiýatynda tanalýan ýazyjy. Onlarça eseri dürli dillere terjime edildi we millionlarça okyjyny özüne çekdi.',
    );
  });

  static const _authorNames = [
    'Osman Ödäýew',
    'Gurbannazar Ezizow',
    'Kerim Gurbannepesow',
    'Agageldi Allanazarow',
    'Bäşim Ataýew',
    'Nurmuhammet Andalyp',
    'Amanmyrat Bugaýew',
    'Rahim Esenow',
    'Hydyr Deryaýew',
    'Berdi Kerbabaýew',
  ];

  static const _titles = [
    'Ýitgi we tapyş', 'Gije gelen myhman', 'Söýginiň soňy ýok', 'Çölüň sesi',
    'Asman ýyldyzlary', 'Ykbal ýollary', 'Garaşan gije', 'Ýalňyz ýürek',
    'Umyt guşy', 'Wagt akymy', 'Gizlin dünýä', 'Soňky söz',
    'Ýaşlyk ýyllary', 'Düýşdäki söýgi', 'Uzak ýoluň ahyry', 'Gara garga',
    'Bagt syry', 'Öý — mukaddes', 'Ykbal çyzgysy', 'Ýürekdäki ot',
    'Söýgi hatlary', 'Dagyň aňyrsynda', 'Ýaz gelende', 'Ynam köprüsi',
    'Ata Watan', 'Ene dilim', 'Çaga ýyllary', 'Iki dünýäniň arasynda',
    'Ýurduň nury', 'Gyş ertekisi', 'Bahar şemaly', 'Deňziň aňyrsy',
    'Ýoluň soňy', 'Görlüp-eşidilmedik', 'Gujagyňda gizlener', 'Dostluk ýoly',
    'Aýralyk agysy', 'Gara gije, ak daň', 'Söýgi we ölüm', 'Wysal güni',
    'Çyn ýürekden', 'Gadymy syrlar', 'Ýitirilen wagt', 'Ykbal oýny',
    'Ýaşaýşyň manysy', 'Ýat illerde', 'Öwrülişik', 'Täleýiň ýazgysy',
    'Şugla', 'Gizlin arzuw',
  ];

  static final genrePool = [
    'Romantika', 'Fantasy', 'Detektif', 'Triller', 'Taryh', 'Klassika',
    'Ylmy-Fantastika', 'Psihologiýa', 'Biografiýa', 'Gorkunç',
  ];

  // 16 real cover photos (assets/images/covers) cycled across however many
  // mock books get generated — there just aren't 50 distinct cover images.
  static const _coverImages = [
    'assets/images/covers/cover_01.jpg', 'assets/images/covers/cover_02.jpg',
    'assets/images/covers/cover_03.jpg', 'assets/images/covers/cover_04.jpg',
    'assets/images/covers/cover_05.jpg', 'assets/images/covers/cover_06.jpg',
    'assets/images/covers/cover_07.jpg', 'assets/images/covers/cover_08.jpg',
    'assets/images/covers/cover_09.jpg', 'assets/images/covers/cover_10.jpg',
    'assets/images/covers/cover_11.jpg', 'assets/images/covers/cover_12.jpg',
    'assets/images/covers/cover_13.jpg', 'assets/images/covers/cover_14.jpg',
    'assets/images/covers/cover_15.jpg', 'assets/images/covers/cover_16.jpg',
  ];

  static List<Book> generateBooks(int count, {int seed = 0}) {
    return List.generate(count, (i) {
      final idx = (i + seed) % _titles.length;
      final authorIdx = (i + seed) % authors.length;
      return Book(
        id: 'book_${seed}_$i',
        title: _titles[idx],
        author: authors[authorIdx],
        coverColor: _coverColors[(i + seed) % _coverColors.length],
        coverImage: _coverImages[(i + seed) % _coverImages.length],
        format: BookFormat.values[(i + seed) % BookFormat.values.length],
        genres: [genrePool[(i + seed) % genrePool.length], genrePool[(i + seed + 3) % genrePool.length]],
        publisher: 'Türkmen Neşirýat',
        pages: 180 + ((i + seed) * 37) % 320,
        readCount: 1200 + ((i + seed) * 913) % 58000,
        purchaseCount: 80 + ((i + seed) * 57) % 4000,
        priceManat: 10 + ((i + seed) * 5) % 40,
        isFree: (i + seed) % 9 == 0,
        synopsis:
            'Bu kitap okyjyny çuňňur duýgulara we pikirlenmelere iterýän, wakalary ýatda galjak gahrymanlar bilen suratlandyrýan täsirli bir eser. Awtoryň öňki eserlerinden tapawutlylykda, bu gezek has çuňňur temalar gozgalýar.',
      );
    });
  }

  // A fixed 50-book pool — every title in _titles used exactly once — for
  // screens that want a stable catalogue instead of an ad-hoc seeded slice.
  static final books = generateBooks(50);

  static final homeSections = <HomeSection>[
    const HomeSection(title: 'Täze Gelenler', subtitle: 'Kitaphana täze goşulan eserler'),
    const HomeSection(title: 'Hepdelik Iň Köp Okunanlar', subtitle: 'Bu hepde okyjylaryň saýlan kitaplary'),
    const HomeSection(title: 'Bestsellers', subtitle: 'Iň köp satylan we halanan eserler'),
    const HomeSection(title: 'Redaktoryň Saýlawlary', subtitle: 'Zihniňizi dönüşdiriň, üstünligi şekillendiriň'),
    const HomeSection(title: 'Romantika', subtitle: 'Ýürek gysdyryjy söýgi hekaýalary'),
    const HomeSection(title: 'Fantasy', subtitle: 'Jadyly dünýälere syýahat ediň'),
    const HomeSection(title: 'Romantasy', subtitle: 'Söýgi we jady bir ýerde'),
    const HomeSection(title: 'Young Adult (ýaş ululara)', subtitle: 'Ýaşlar üçin täsirli hekaýalar'),
    const HomeSection(title: 'Psihologik Triller', subtitle: 'Zehinli, dartgynly wakalar'),
    const HomeSection(title: 'Gerilim (Triller)', subtitle: 'Demiňizi tutup okarsyňyz'),
    const HomeSection(title: 'Detektif', subtitle: 'Syrlary çözüň, jenaýaty tapyň'),
    const HomeSection(title: 'True Crime', subtitle: 'Hakyky jenaýat wakalary'),
    const HomeSection(title: 'Romantik Komediýa', subtitle: 'Gülkili we ýürek gyzdyryjy'),
    const HomeSection(title: 'Sport Romantikasy', subtitle: 'Yşk we ýaryş bir ýerde'),
    const HomeSection(title: 'Nefretden Söýgä', subtitle: 'Ýigrençden söýgä barýan ýol'),
    const HomeSection(title: 'Gorkunç (Horror)', subtitle: 'Gorky duýgularyňyzy synaň'),
    const HomeSection(title: 'Ylmy-Fantastika (Sci-Fi)', subtitle: 'Geljegiň we tehnologiýanyň dünýäsi'),
    const HomeSection(title: 'Distopiýa', subtitle: 'Garaňky geljek hekaýalary'),
    const HomeSection(title: 'Türk Ýazarlar', subtitle: 'Türk edebiýatynyň iň gowy eserleri'),
    const HomeSection(title: 'Wattpad Kitaplary', subtitle: 'Millionlarça okyjynyň halan eserleri'),
    const HomeSection(title: 'Manga / Manhwa / Webtoon / Anime', subtitle: 'Illýustrirlenen hekaýalar dünýäsi'),
    const HomeSection(title: 'K-Drama / C-Drama', subtitle: 'Ekrandan sahypa geçen hekaýalar'),
    const HomeSection(title: 'Komikslar', subtitle: 'Suratly hekaýalar we gahrymanlar'),
    const HomeSection(title: 'Şekilli Kitaplar', subtitle: 'Suratlar bilen baýlaşdyrylan eserler'),
    const HomeSection(title: 'Çaga Kitaplary', subtitle: 'Çagalar üçin gyzykly hekaýalar'),
  ];

  // Kolleksiýalar row — big cards, each its own 50-book set.
  static final collections = <BookCollection>[
    BookCollection(
      title: 'New York Times Bestsellers',
      emoji: '🏆',
      gradient: const [Color(0xFFE8712C), Color(0xFFB44BE8)],
      books: generateBooks(50, seed: 101),
    ),
    BookCollection(
      title: 'Film + Kitap',
      emoji: '🎬',
      gradient: const [Color(0xFF3B5B6B), Color(0xFF1C1C27)],
      books: generateBooks(50, seed: 202),
    ),
    BookCollection(
      title: 'Nobel baýrakly kitaplar',
      emoji: '🏅',
      gradient: const [Color(0xFF6B5B3B), Color(0xFF3B3B3B)],
      books: generateBooks(50, seed: 303),
    ),
    BookCollection(
      title: 'Booker baýramy',
      emoji: '📚',
      gradient: const [Color(0xFF3B6B4A), Color(0xFF1C1C27)],
      books: generateBooks(50, seed: 404),
    ),
    BookCollection(
      title: 'TikTok / BookTok Baýraklary',
      emoji: '📱',
      gradient: const [Color(0xFFF77E68), Color(0xFFB44BE8)],
      books: generateBooks(50, seed: 505),
    ),
  ];

  // Book series ("Seriýalar") — 14 of them so the HomeScreen row shows the
  // first 10 and the "Ählisi" page has extras. Each holds an ordered set of
  // books; the count varies per series.
  static final series = <BookSeries>[
    _series('Seriýa «Talisman Akademiýasy»', 7, 1, 11),
    _series('Seriýa «Netijeli Jady»', 17, 2, 22),
    _series('Seriýa «Ýyldyzlar Söweşi»', 12, 3, 33),
    _series('Seriýa «Aždarha Tagty»', 9, 4, 44),
    _series('Seriýa «Gölgeler Möwsümi»', 5, 5, 55),
    _series('Seriýa «Wagt Sakçylary»', 8, 6, 66),
    _series('Seriýa «Gadymy Ganhorlar»', 6, 7, 77),
    _series('Seriýa «Buzly Şalyk»', 10, 8, 88),
    _series('Seriýa «Ýitirilen Şäher»', 4, 9, 99),
    _series('Seriýa «Ganatly Söýgi»', 13, 10, 110),
    _series('Seriýa «Kölegäniň Syry»', 7, 11, 121),
    _series('Seriýa «Otly Ýürek»', 11, 12, 132),
    _series('Seriýa «Deňziň Aňyrsy»', 6, 13, 143),
    _series('Seriýa « Soňky Jadygöý»', 9, 14, 154),
  ];

  static BookSeries _series(String title, int count, int coverIdx, int seed) {
    return BookSeries(
      title: title,
      coverImage: _coverImages[coverIdx % _coverImages.length],
      books: generateBooks(count, seed: seed),
    );
  }

  static final popularSearches = [
    'Söýgi hekaýasy', 'Fantasy', 'Detektif', 'Türk ýazarlar', 'Klassika', 'Manga', 'Psihologiýa',
  ];

  static final quickFilterChips = [
    'Türk dili', 'Romant.', 'Mugt', 'Täze', 'EPUB', 'Bestseller',
  ];
}
